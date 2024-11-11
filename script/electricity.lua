Electricity = {}

local remote_api = require "script.lib"
local find_surrounding_factory = remote_api.find_surrounding_factory
local get_factory_by_building = remote_api.get_factory_by_building

local function get_or_create_inside_power_pole(factory)
	if factory._inside_power_pole and factory._inside_power_pole.valid then
		return factory._inside_power_pole
	end

	local layout = factory.layout
	local power_pole = factory.inside_surface.create_entity {
		name = "factory-power-pole",
		position = {factory.inside_x + layout.inside_energy_x, factory.inside_y + layout.inside_energy_y},
		force = factory.force,
		quality = factory.quality
	}
	power_pole.destructible = false
	factory._inside_power_pole = power_pole

	if factory.inside_surface.planet then
		local planet_name = factory.inside_surface.planet.name
		local parent_planet = game.planets[planet_name:gsub("%-factory%-floor", "")]
		if parent_planet then
			local scale = 1

			local sprite_data = {
				sprite = "space-location/" .. parent_planet.name,
				surface = factory.inside_surface,
				target = {
					entity = power_pole
				},
				only_in_alt_mode = true,
				render_layer = "entity-info-icon",
			}
			-- Fake shadows
			local shadow_radius = 0.12 * scale
			for _, shadow_offset in pairs {{0, shadow_radius}, {0, -shadow_radius}, {shadow_radius, 0}, {-shadow_radius, 0}} do
				sprite_data.tint = {0, 0, 0, 0.5} -- Transparent black
				sprite_data.target.offset = shadow_offset
				rendering.draw_sprite(sprite_data)
			end
			-- Proper sprite
			sprite_data.tint = nil
			sprite_data.target.offset = nil
			rendering.draw_sprite(sprite_data)
		end
	end

	return factory._inside_power_pole
end
Electricity.get_or_create_inside_power_pole = get_or_create_inside_power_pole

local function connect_power(factory, outside_power_pole)
	local inside_power_pole = get_or_create_inside_power_pole(factory)
	local outside_power_pole_wire_connector = outside_power_pole.get_wire_connector(defines.wire_connector_id.pole_copper)
	local inside_power_pole_wire_connector = inside_power_pole.get_wire_connector(defines.wire_connector_id.pole_copper)
	inside_power_pole_wire_connector.connect_to(outside_power_pole_wire_connector, false, defines.wire_origin.script)
end

local function update_power_connection(factory, pole) -- pole parameter is optional
	if not factory.outside_energy_receiver or not factory.outside_energy_receiver.valid then return end
	local electric_network = factory.outside_energy_receiver.electric_network_id
	if electric_network == nil then return end

	local surface = factory.outside_surface
	local x = factory.outside_x
	local y = factory.outside_y

	if storage.surface_factories[surface.index] then
		local surrounding = find_surrounding_factory(surface, {x = x, y = y})
		if surrounding then
			connect_power(factory, get_or_create_inside_power_pole(surrounding))
			return
		end
	end

	-- find the nearest connected power pole
	local D = prototypes.max_electric_pole_supply_area_distance + factory.layout.outside_size / 2
	local area = {{x - D, y - D}, {x + D, y + D}}
	local has_global_electric_network = surface.has_global_electric_network
	if has_global_electric_network then area = nil end

	local candidates = {}
	for _, entity in pairs(surface.find_entities_filtered {type = "electric-pole", area = area, limit = 100}) do
		local same_network = has_global_electric_network or entity.electric_network_id == electric_network
		if same_network and entity ~= pole and not entity.prototype.hidden then
			candidates[#candidates + 1] = entity
		end
	end

	if #candidates == 0 then return end
	connect_power(factory, surface.get_closest({x, y}, candidates))
end
Electricity.update_power_connection = update_power_connection

local function get_factories_near_pole(pole)
	local surface = pole.surface

	local D = pole.prototype.get_supply_area_distance(pole.quality)
	if D == 0 then return {} end
	D = D + 1
	local position = pole.position
	local x = position.x
	local y = position.y
	local area = {{x - D, y - D}, {x + D, y + D}}
	if surface.has_global_electric_network then area = nil end

	local result = {}
	for _, candidate in pairs(surface.find_entities_filtered {type = BUILDING_TYPE, area = area}) do
		if has_layout(candidate.name) then result[#result + 1] = get_factory_by_building(candidate) end
	end
	return result
end

function Electricity.power_pole_placed(pole)
	for _, factory in pairs(get_factories_near_pole(pole)) do
		if not factory.outside_energy_receiver.valid then goto continue end
		local electric_network = factory.outside_energy_receiver.electric_network_id
		if not electric_network or electric_network ~= pole.electric_network_id then goto continue end
		connect_power(factory, pole)

		::continue::
	end
end

function Electricity.power_pole_destroyed(pole)
	local wire_connector = pole.get_wire_connector(defines.wire_connector_id.pole_copper)

	local old_connections = wire_connector.connections
	Electricity.disconnect_all_copper_connections(pole)

	for _, factory in pairs(get_factories_near_pole(pole)) do
		update_power_connection(factory, pole)
	end

	for _, connection in pairs(old_connections) do
		wire_connector.connect_to(connection.target)
	end
end

script.on_event(defines.events.on_player_selected_area, function(event)
	if event.item == "power-grid-comb" then
		for _, building in pairs(event.entities) do
			if has_layout(building.name) then
				local factory = get_factory_by_building(building)
				if factory then update_power_connection(factory) end
			end
		end
	end
end)

-- prevent SHIFT+CLICK on factory power poles
script.on_event({defines.events.on_selected_entity_changed, defines.events.on_player_cursor_stack_changed}, function(event)
	local player = game.get_player(event.player_index)
	local pole = player.selected
	if pole and pole.type == "electric-pole" then
		local permission = player.permission_group
		if not permission then
			permission = game.permissions.create_group()
			player.permission_group = permission
		end

		local has_cross_surface_connections = false
		for _, connection in pairs(pole.get_wire_connector(defines.wire_connector_id.pole_copper).connections) do
			local owner = connection.target.owner
			if owner.surface ~= pole.surface then
				has_cross_surface_connections = true
				break
			end
		end
		
		permission.set_allows_action(defines.input_action.remove_cables, not has_cross_surface_connections)
	end

	Camera.update_camera(player) -- also update camera here
end)

function Electricity.cleanup_factory_exterior(factory)
	factory.outside_energy_receiver.destroy()
	local pole = Electricity.get_or_create_inside_power_pole(factory)
	Electricity.disconnect_all_copper_connections(pole)

	if not factory.inside_surface.valid then return end

	local recursive_children = remote_api.find_factories_by_area {
		surface = factory.inside_surface,
		area = {
			{factory.inside_x - 128, factory.inside_y - 128},
			{factory.inside_x + 128, factory.inside_y + 128}
		}
	}

	for _, child in pairs(recursive_children) do
		if child ~= factory then
			Electricity.update_power_connection(child)
		end
	end
end

function Electricity.disconnect_all_copper_connections(pole)
	local wire_connector = pole.get_wire_connector(defines.wire_connector_id.pole_copper)
	wire_connector.disconnect_all(defines.wire_origin.player)
	wire_connector.disconnect_all(defines.wire_origin.script)
	wire_connector.disconnect_all(defines.wire_origin.radar)
end