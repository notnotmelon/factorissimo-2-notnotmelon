require "util"

create_flying_text = function(args)
	args.create_at_cursor = false
	for _, player in pairs(game.connected_players) do
		player.create_local_flying_text(args)
	end
end

local remote_api = require "script.lib"
local get_factory_by_building = remote_api.get_factory_by_building
local find_surrounding_factory = remote_api.find_surrounding_factory
local BUILDING_TYPE = BUILDING_TYPE

require "script.layout"
local has_layout = Layout.has_layout
require "script.connections.connections"
require "script.blueprint"
require "script.camera"
require "script.travel"
require "script.overlay"
require "script.pollution"
require "script.electricity"
require "script.greenhouse"
require "script.lights"
require "script.roboport.roboport"
require "compat.factoriomaps"

local update_hidden_techs -- Function stub
local activate_factories  -- Function stub

-- INITIALIZATION --

local function init_globals()
	Camera.init()
	Layout.init()
	Connections.init()
	Roboport.init()

	-- List of all factories
	storage.factories = storage.factories or {}
	-- Map: Id from item-with-tags -> Factory
	storage.saved_factories = storage.saved_factories or {}
	-- Map: Player or robot -> Save name to give him on the next relevant event
	storage.pending_saves = storage.pending_saves or {}
	-- Map: Entity unit number -> Factory it is a part of
	storage.factories_by_entity = storage.factories_by_entity or {}
	-- Map: Surface index -> list of factories on it
	storage.surface_factories = storage.surface_factories or {}
	-- Scalar
	storage.next_factory_surface = storage.next_factory_surface or 0
	-- Map: Player index -> Last teleport time
	storage.last_player_teleport = storage.last_player_teleport or {}
	-- Map: Player index -> Whether preview is activated
	storage.player_preview_active = storage.player_preview_active or {}

	if remote.interfaces["PickerDollies"] then
		remote.call("PickerDollies", "add_blacklist_name", "factory-1", true)
		remote.call("PickerDollies", "add_blacklist_name", "factory-2", true)
		remote.call("PickerDollies", "add_blacklist_name", "factory-3", true)
	end

	-- Fix common migration issues.
	for _, factory in pairs(storage.factories) do
		-- Fix issues when forces are deleted.
		if not factory.force or not factory.force.valid then
			factory.force = game.forces.player
		end
		-- Fix issues when quality prototypes are removed.
		if not factory.quality or not factory.quality.valid then
			if factory.building and factory.building.valid then
				factory.quality = factory.building.quality
			else
				factory.quality = prototypes.quality.normal
			end
		end
	end
end

script.on_init(function()
	init_globals()
	for _, force in pairs(game.forces) do
		update_hidden_techs(force)
	end
	Compat.handle_factoriomaps()
end)

script.on_load(function()
	Compat.handle_factoriomaps()
end)

script.on_configuration_changed(function(config_changed_data)
	init_globals()
	activate_factories()

	if remote.interfaces["RSO"] then
		for surface_index, _ in pairs(storage.surface_factories or {}) do
			local surface = game.get_surface(surface_index)
			if surface then pcall(remote.call, "RSO", "ignoreSuface", surface.name) end
		end
	end

	storage.items_with_metadata = nil
end)

-- FACTORY GENERATION --

local function update_destructible(factory)
	if factory.built and factory.building.valid then
		factory.building.destructible = not settings.global["Factorissimo2-indestructible-buildings"].value
	end
end

local function get_surface_name(layout, parent_surface)
	if layout.surface_override then return layout.surface_override end

	if parent_surface.planet then
		return (parent_surface.name .. "-factory-floor"):gsub("%-factory%-floor%-factory%-floor", "-factory-floor")
	end

	storage.next_factory_surface = storage.next_factory_surface + 1
	return "factory-floor-" .. storage.next_factory_surface
end

script.on_event(defines.events.on_surface_created, function(event)
	local surface = game.get_surface(event.surface_index)
	if not surface.name:find("%-factory%-floor$") and not surface.name:find("^factory%-floor%-%d+$") then return end

	surface.freeze_daytime = true
	surface.daytime = 0.5
	if remote.interfaces["RSO"] then
		pcall(remote.call, "RSO", "ignoreSurface", surface.name)
	end
	local mgs = surface.map_gen_settings
	mgs.width = 2
	mgs.height = 2
	surface.map_gen_settings = mgs

	for _, force in pairs(game.forces) do
		if force.technologies["factory-interior-upgrade-lights"].researched then
			surface.daytime = 1
			break
		end
	end
end)

local function create_factory_position(layout, building)
	local parent_surface = building.surface
	local surface_name = get_surface_name(layout, parent_surface)
	local surface = game.get_surface(surface_name)

	if not surface then
		if remote.interfaces["RSO"] then -- RSO compatibility
			pcall(remote.call, "RSO", "ignoreSurface", surface_name)
		end

		local planet = game.planets[surface_name]
		if planet then
			surface = planet.surface or planet.create_surface()
		end

		if not surface then
			surface = game.create_surface(surface_name, {width = 2, height = 2})
		end

		surface.daytime = 0.5
		surface.freeze_daytime = true
	end

	local n = 0
	for _, factory in pairs(storage.factories) do
		if factory.inside_surface.valid and factory.inside_surface == surface then n = n + 1 end
	end

	local FACTORISSIMO_CHUNK_SPACING = 16
	local cx = FACTORISSIMO_CHUNK_SPACING * (n % 8)
	local cy = FACTORISSIMO_CHUNK_SPACING * math.floor(n / 8)
	-- To make void chnks show up on the map, you need to tell them they've finished generating.
	for xx = -2, 2 do
		for yy = -2, 2 do
			surface.set_chunk_generated_status({cx + xx, cy + yy}, defines.chunk_generated_status.entities)
		end
	end
	surface.destroy_decoratives {area = {{32 * (cx - 2), 32 * (cy - 2)}, {32 * (cx + 2), 32 * (cy + 2)}}}

	local factory = {}
	factory.inside_surface = surface
	factory.inside_x = 32 * cx
	factory.inside_y = 32 * cy
	factory.stored_pollution = 0
	factory.outside_x = building.position.x
	factory.outside_y = building.position.y
	factory.outside_door_x = factory.outside_x + layout.outside_door_x
	factory.outside_door_y = factory.outside_y + layout.outside_door_y
	factory.outside_surface = building.surface

	storage.surface_factories[surface.index] = storage.surface_factories[surface.index] or {}
	storage.surface_factories[surface.index][n + 1] = factory

	local fn = table_size(storage.factories) + 1
	storage.factories[fn] = factory
	factory.id = fn

	return factory
end

local function add_tile_rect(tiles, tile_name, xmin, ymin, xmax, ymax) -- tiles is rw
	local i = #tiles
	for x = xmin, xmax - 1 do
		for y = ymin, ymax - 1 do
			i = i + 1
			tiles[i] = {name = tile_name, position = {x, y}}
		end
	end
end

local function add_hidden_tile_rect(factory)
	local surface = factory.inside_surface
	local layout = factory.layout
	local xmin = factory.inside_x - 64
	local ymin = factory.inside_y - 64
	local xmax = factory.inside_x + 64
	local ymax = factory.inside_y + 64

	local position = {0, 0}
	for x = xmin, xmax - 1 do
		for y = ymin, ymax - 1 do
			position[1] = x
			position[2] = y
			surface.set_hidden_tile(position, "water")
		end
	end
end

local function add_tile_mosaic(tiles, tile_name, xmin, ymin, xmax, ymax, pattern) -- tiles is rw
	local i = #tiles
	for x = 0, xmax - xmin - 1 do
		for y = 0, ymax - ymin - 1 do
			if (string.sub(pattern[y + 1], x + 1, x + 1) == "+") then
				i = i + 1
				tiles[i] = {name = tile_name, position = {x + xmin, y + ymin}}
			end
		end
	end
end

local function build_factory_upgrades(factory)
	Lights.build_lights_upgrade(factory)
	Greenhouse.build_greenhouse_upgrade(factory)
	Overlay.build_display_upgrade(factory)
	Roboport.build_roboport_upgrade(factory)
end

local function create_factory_interior(layout, building)
	local force = building.force

	local factory = create_factory_position(layout, building)
	factory.building = building
	factory.layout = layout
	factory.force = force
	factory.quality = building.quality
	factory.inside_door_x = layout.inside_door_x + factory.inside_x
	factory.inside_door_y = layout.inside_door_y + factory.inside_y
	local tiles = {}
	for _, rect in pairs(layout.rectangles) do
		add_tile_rect(tiles, rect.tile, rect.x1 + factory.inside_x, rect.y1 + factory.inside_y, rect.x2 + factory.inside_x, rect.y2 + factory.inside_y)
	end
	for _, mosaic in pairs(layout.mosaics) do
		add_tile_mosaic(tiles, mosaic.tile, mosaic.x1 + factory.inside_x, mosaic.y1 + factory.inside_y, mosaic.x2 + factory.inside_x, mosaic.y2 + factory.inside_y, mosaic.pattern)
	end
	for _, cpos in pairs(layout.connections) do
		table.insert(tiles, {name = layout.connection_tile, position = {factory.inside_x + cpos.inside_x, factory.inside_y + cpos.inside_y}})
	end
	factory.inside_surface.set_tiles(tiles)
	add_hidden_tile_rect(factory)

	Electricity.get_or_create_inside_power_pole(factory)

	local radar = factory.inside_surface.create_entity {
		name = "factory-hidden-radar",
		position = {factory.inside_x, factory.inside_y},
		force = force,
	}
	radar.destructible = false
	factory.radar = radar
	factory.inside_overlay_controllers = {}

	factory.connections = {}
	factory.connection_settings = {}
	factory.connection_indicators = {}

	return factory
end

local function create_factory_exterior(factory, building)
	local layout = factory.layout
	local force = factory.force
	factory.outside_x = building.position.x
	factory.outside_y = building.position.y
	factory.outside_door_x = factory.outside_x + layout.outside_door_x
	factory.outside_door_y = factory.outside_y + layout.outside_door_y
	factory.outside_surface = building.surface

	local oer = factory.outside_surface.create_entity {name = layout.outside_energy_receiver_type, position = {factory.outside_x, factory.outside_y}, force = force}
	oer.destructible = false
	oer.operable = false
	oer.rotatable = false
	factory.outside_energy_receiver = oer

	factory.outside_overlay_displays = {}
	factory.outside_port_markers = {}

	storage.factories_by_entity[building.unit_number] = factory
	factory.building = building
	factory.built = true

	Connections.recheck_factory(factory, nil, nil)
	Electricity.update_power_connection(factory)
	Overlay.update_overlay(factory)
	update_destructible(factory)
	build_factory_upgrades(factory)
	return factory
end

local function toggle_port_markers(factory)
	if not factory.built then return end
	if #(factory.outside_port_markers) == 0 then
		for id, cpos in pairs(factory.layout.connections) do
			local sprite_data = {
				sprite = "utility/indication_arrow",
				orientation = cpos.direction_out / 16,
				target = {
					entity = factory.building,
					offset = {cpos.outside_x - 0.5 * cpos.indicator_dx, cpos.outside_y - 0.5 * cpos.indicator_dy}
				},
				surface = factory.building.surface,
				only_in_alt_mode = true,
				render_layer = "entity-info-icon",
			}
			table.insert(factory.outside_port_markers, rendering.draw_sprite(sprite_data).id)
		end
	else
		for _, sprite in pairs(factory.outside_port_markers) do
			local object = rendering.get_object_by_id(sprite)
			if object then object.destroy() end
		end
		factory.outside_port_markers = {}
	end
end

local function cleanup_factory_exterior(factory, building)
	Electricity.cleanup_factory_exterior(factory)
	Roboport.cleanup_factory_exterior(factory)

	Connections.disconnect_factory(factory)
	for _, render_id in pairs(factory.outside_overlay_displays) do
		local object = rendering.get_object_by_id(render_id)
		if object then object.destroy() end
	end
	factory.outside_overlay_displays = {}
	for _, render_id in pairs(factory.outside_port_markers) do
		local object = rendering.get_object_by_id(render_id)
		if object then object.destroy() end
	end
	factory.outside_port_markers = {}
	factory.building = nil
	factory.built = false
end

-- FACTORY SAVING AND LOADING --

commands.add_command("give-lost-factory-buildings", {"command-help-message.give-lost-factory-buildings"}, function(event)
	local player = game.players[event.player_index]
	if not (player and player.connected and player.admin) then return end
	local inventory = player.get_main_inventory()
	if not inventory then return end
	for id, factory in pairs(storage.saved_factories) do
		for i = 1, #inventory do
			local stack = inventory[i]
			if stack.valid_for_read and stack.name == factory.layout.name and stack.type == "item-with-tags" and stack.tags.id == id then goto found end
		end
		player.insert {name = factory.layout.name .. "-instantiated", count = 1, tags = {id = id}}
		::found::
	end
end)

-- FACTORY PLACEMENT AND DESTRUCTION --

local function can_place_factory_here(tier, surface, position)
	local factory = find_surrounding_factory(surface, position)
	if not factory then return true end
	local outer_tier = factory.layout.tier
	if outer_tier > tier and (factory.force.technologies["factory-recursion-t1"].researched or settings.global["Factorissimo2-free-recursion"].value) then return true end
	if (outer_tier >= tier or settings.global["Factorissimo2-better-recursion-2"].value)
		and (factory.force.technologies["factory-recursion-t2"].researched or settings.global["Factorissimo2-free-recursion"].value) then
		return true
	end
	if outer_tier > tier then
		create_flying_text {position = position, text = {"factory-connection-text.invalid-placement-recursion-1"}}
	elseif (outer_tier >= tier or settings.global["Factorissimo2-better-recursion-2"].value) then
		create_flying_text {position = position, text = {"factory-connection-text.invalid-placement-recursion-2"}}
	else
		create_flying_text {position = position, text = {"factory-connection-text.invalid-placement"}}
	end
	return false
end

-- When a connection piece is placed or destroyed, check if can be connected to a factory building
local function recheck_nearby_connections(entity, delayed)
	local surface = entity.surface
	local pos = entity.position

	local collision_box = entity.prototype.collision_box
	if orientation == 0 then     -- north
		-- collision_box is fine
	elseif orientation == 0.5 then -- south
		collision_box.left_top.y, collision_box.right_bottom.y = -collision_box.right_bottom.y, -collision_box.left_top.y
	elseif orientation == 0.25 then -- east
		collision_box.left_top.y, collision_box.left_top.x, collision_box.right_bottom.x, collision_box.right_bottom.y = -collision_box.right_bottom.x, -collision_box.right_bottom.y, -collision_box.left_top.y, -collision_box.left_top.x
	elseif orientation == 0.75 then -- west
		collision_box.left_top.y, collision_box.right_bottom.y = -collision_box.right_bottom.y, -collision_box.left_top.y
		collision_box.left_top.y, collision_box.left_top.x, collision_box.right_bottom.x, collision_box.right_bottom.y = -collision_box.right_bottom.x, -collision_box.right_bottom.y, -collision_box.left_top.y, -collision_box.left_top.x
	end

	-- Expand collision box to grid-aligned
	collision_box.left_top.x = math.floor(collision_box.left_top.x)
	collision_box.left_top.y = math.floor(collision_box.left_top.y)
	collision_box.right_bottom.x = math.ceil(collision_box.right_bottom.x)
	collision_box.right_bottom.y = math.ceil(collision_box.right_bottom.y)

	-- Expand box to catch factories and also avoid illegal zero-area finds
	local bounding_box = {
		left_top = {x = pos.x - 0.3 + collision_box.left_top.x, y = pos.y - 0.3 + collision_box.left_top.y},
		right_bottom = {x = pos.x + 0.3 + collision_box.right_bottom.x, y = pos.y + 0.3 + collision_box.right_bottom.y}
	}

	for _, candidate in pairs(surface.find_entities_filtered {area = bounding_box, type = BUILDING_TYPE}) do
		if candidate ~= entity and has_layout(candidate.name) then
			local factory = get_factory_by_building(candidate)
			if factory then
				if delayed then
					Connections.recheck_factory_delayed(factory, bounding_box, nil)
				else
					Connections.recheck_factory(factory, bounding_box, nil)
				end
			end
		end
	end
	local factory = find_surrounding_factory(surface, pos)
	if factory then
		if delayed then
			Connections.recheck_factory_delayed(factory, nil, bbox)
		else
			Connections.recheck_factory(factory, nil, bbox)
		end
	end
end

local function create_fresh_factory(entity)
	local layout = Layout.create_layout(entity.name, entity.quality)
	local factory = create_factory_interior(layout, entity)
	create_factory_exterior(factory, entity)
	factory.inactive = not can_place_factory_here(layout.tier, entity.surface, entity.position)
	return factory
end

local function handle_factory_placed(entity, tags)
	if not tags or not tags.id then
		create_fresh_factory(entity)
		return
	end

	local factory = storage.saved_factories[tags.id]
	storage.saved_factories[tags.id] = nil
	if factory and factory.inside_surface and factory.inside_surface.valid then
		-- This is a saved factory, we need to unpack it
		factory.quality = entity.quality
		create_factory_exterior(factory, entity)
		factory.inactive = not can_place_factory_here(factory.layout.tier, entity.surface, entity.position)
		return
	end

	if not factory and storage.factories[tags.id] then
		-- This factory was copied from somewhere else. Clone all contained entities
		local factory = create_fresh_factory(entity)
		Blueprint.copy_entity_ghosts(storage.factories[tags.id], factory)
		Overlay.update_overlay(factory)
		return
	end

	create_flying_text {position = entity.position, text = {"factory-connection-text.invalid-factory-data"}}
	entity.destroy()
end

local BOREHOLE_PUMP_FIXED_RECIPES = {
	["nauvis"] = "borehole-pump-water",
	["gleba"] = "borehole-pump-water",
	["vulcanus"] = "borehole-pump-lava",
	["fulgora"] = "borehole-pump-heavy-oil",
	["aquilo"] = "borehole-pump-ammoniacal-solution",
}
local BOREHOLE_PUMP_SMOKE_OFFSETS = {
	[defines.direction.north] = {-1.2, -2.1},
	[defines.direction.east] = {0.3, -2.2},
	[defines.direction.south] = {0, -2.2},
	[defines.direction.west] = {-2, -2},
}
local function get_borehole_smoke_position(borehole)
	local offset = BOREHOLE_PUMP_SMOKE_OFFSETS[borehole.direction]
	return {borehole.position.x + offset[1], borehole.position.y + offset[2]}
end

local function on_build_borehole_pump(borehole)
	local surface = borehole.surface
	local parent_planet_name = surface.name:gsub("%-factory%-floor$", "")
	local parent_planet = game.planets[parent_planet_name]
	if not parent_planet then return end
	local fixed_recipe = BOREHOLE_PUMP_FIXED_RECIPES[parent_planet_name]
	if not fixed_recipe then return end

	borehole.set_recipe(fixed_recipe)
	borehole.recipe_locked = true

	local smokestack = surface.create_entity {
		name = "borehole-pump-smokestack",
		position = get_borehole_smoke_position(borehole),
		force = borehole.force_index
	}
	smokestack.destroy() -- Instantly destroy the first smokestack. This handles the case when the borehole is initally unpowered.

	storage.borehole_smokestacks = storage.borehole_smokestacks or {}
	storage.borehole_smokestacks[borehole.unit_number] = {borehole = borehole, smokestack = smokestack}
end

local function update_borehole_smokestacks()
	for unit_number, smokestack_data in pairs(storage.borehole_smokestacks or {}) do
		local borehole, smokestack = smokestack_data.borehole, smokestack_data.smokestack
		if not borehole.valid then
			if smokestack.valid then smokestack.destroy() end
			storage.borehole_smokestacks[unit_number] = nil
			update_borehole_smokestacks()
			return
		elseif not smokestack.valid and borehole.energy > 0 and borehole.is_crafting() and borehole.crafting_progress ~= 1 then
			smokestack_data.smokestack = borehole.surface.create_entity {
				name = "borehole-pump-smokestack",
				position = get_borehole_smoke_position(borehole),
				force = borehole.force_index
			}
		end
	end
end

script.on_nth_tick(33, update_borehole_smokestacks)

local blueprintable_factory_peripherals = {
	["factory-construction-roboport"] = true,
	["factory-construction-chest"] = true,
	["factory-overlay-controller"] = true,
	["factory-blueprint-anchor"] = true,
}

script.on_event({
	defines.events.on_built_entity,
	defines.events.on_robot_built_entity,
	defines.events.on_space_platform_built_entity,
	defines.events.script_raised_built,
	defines.events.script_raised_revive
}, function(event)
	local entity = event.created_entity or event.entity
	local entity_name, entity_type = entity.name, entity.type

	if blueprintable_factory_peripherals[entity_name] then
		entity.destroy()
		return
	end

	if entity_name == "borehole-pump" then
		on_build_borehole_pump(entity)
		return
	end

	if has_layout(entity_name) then
		local inventory = event.consumed_items
		local tags = event.tags or (inventory and not inventory.is_empty() and inventory[1].valid_for_read and inventory[1].is_item_with_tags and inventory[1].tags) or nil
		handle_factory_placed(entity, tags)
		return
	end

	if Connections.is_connectable(entity) then
		if entity_name == "factory-circuit-connector" then
			entity.operable = false
		else
			local _, _, pipe_name_input = entity_name:find("^factory%-(.*)%-input$")
			local _, _, pipe_name_output = entity_name:find("^factory%-(.*)%-output$")
			local pipe_name = pipe_name_input or pipe_name_output
			if pipe_name then entity = remote_api.replace_entity(entity, pipe_name) end
		end

		recheck_nearby_connections(entity)
		return
	end

	if entity_type == "electric-pole" then
		Electricity.power_pole_placed(entity)
		return
	end

	if entity_type ~= "entity-ghost" then return end
	local ghost_name = entity.ghost_name

	if blueprintable_factory_peripherals[ghost_name] then
		entity.destroy()
		return
	end

	if Connections.indicator_names[ghost_name] then
		Blueprint.unpack_connection_settings_from_blueprint(entity)
		entity.destroy()
	elseif has_layout(ghost_name) and entity.tags then
		local copied_from_factory = storage.factories[entity.tags.id]
		if copied_from_factory then
			Overlay.update_overlay(copied_from_factory, entity)
		end
	end
end)

local sprite_path_translation = {
	virtual = "virtual-signal",
}
local function generate_factory_item_description(factory)
	local overlay = factory.inside_overlay_controller
	local params = {}
	if overlay and overlay.valid then
		for _, section in pairs(overlay.get_or_create_control_behavior().sections) do
			for _, filter in pairs(section.filters) do
				if filter.value and filter.value.name then
					local sprite_type = sprite_path_translation[filter.value.type] or filter.value.type
					table.insert(params, "[" .. sprite_type .. "=" .. filter.value.name .. "]")
				end
			end
		end
	end
	local params = table.concat(params, "\n")
	if params ~= "" then return "[font=heading-2]" .. params .. "[/font]" end
end

-- How players pick up factories
-- Working factory buildings don't return items, so we have to manually give the player an item
script.on_event({
	defines.events.on_player_mined_entity,
	defines.events.on_robot_mined_entity,
	defines.events.on_space_platform_mined_entity
}, function(event)
	local entity = event.entity
	if has_layout(entity.name) then
		local factory = get_factory_by_building(entity)
		if not factory then return end
		cleanup_factory_exterior(factory, entity)
		storage.saved_factories[factory.id] = factory
		local buffer = event.buffer
		buffer.clear()
		buffer.insert {
			name = factory.layout.name .. "-instantiated",
			count = 1,
			tags = {id = factory.id},
			custom_description = generate_factory_item_description(factory),
			quality = entity.quality,
			health = entity.health / entity.max_health
		}
	elseif Connections.is_connectable(entity) then
		recheck_nearby_connections(entity, true) -- Delay
	elseif entity.type == "electric-pole" then
		Electricity.power_pole_destroyed(entity)
	end
end)

local function rebuild_factory(entity)
	local factory = get_factory_by_building(entity)
	if not factory then return end
	storage.factories_by_entity[entity.unit_number] = nil
	local entity = entity.surface.create_entity {
		name = entity.name,
		position = entity.position,
		force = entity.force,
		raise_built = false,
		create_build_effect_smoke = false,
		player = entity.last_user
	}
	storage.factories_by_entity[entity.unit_number] = factory
	factory.building = entity
	Overlay.update_overlay(factory)
	if #factory.outside_port_markers ~= 0 then
		factory.outside_port_markers = {}
		toggle_port_markers(factory)
	end
	create_flying_text {position = entity.position, text = {"factory-cant-be-mined"}}
end

local fake_robots = {["repair-block-robot"] = true} -- Modded construction robots with heavy control scripting
script.on_event(defines.events.on_robot_pre_mined, function(event)
	local entity = event.entity
	if has_layout(entity.name) and fake_robots[event.robot.name] then
		rebuild_factory(entity)
		entity.destroy()
	elseif Connections.is_connectable(entity) then
		recheck_nearby_connections(entity, true) -- Delay
	elseif entity.type == "item-entity" and entity.stack.valid_for_read and has_layout(entity.stack.name) then
		event.robot.destructible = false
	end
end)

-- How biters pick up factories
-- Too bad they don't have hands
script.on_event(defines.events.on_entity_died, function(event)
	local entity = event.entity
	if has_layout(entity.name) then
		local factory = get_factory_by_building(entity)
		if not factory then return end
		storage.saved_factories[factory.id] = factory
		cleanup_factory_exterior(factory, entity)

		entity.surface.spill_item_stack {
			position = entity.position,
			stack = {
				name = factory.layout.name .. "-instantiated",
				tags = {id = factory.id},
				quality = entity.quality.name,
				count = 1,
				custom_description = generate_factory_item_description(factory)
			},
			enable_looted = true,
			force = entity.force_index,
			allow_belts = false,
			max_radius = 0,
			use_start_position_on_failure = true
		}
	elseif Connections.is_connectable(entity) then
		recheck_nearby_connections(entity, true) -- Delay
	elseif entity.type == "electric-pole" then
		Electricity.power_pole_destroyed(entity)
	end
end)

script.on_event(defines.events.on_post_entity_died, function(event)
	if not has_layout(event.prototype.name) or not event.ghost then return end
	local factory = storage.factories_by_entity[event.unit_number]
	if not factory then return end
	event.ghost.tags = {id = factory.id}
end)

-- Just rebuild the factory in this case
script.on_event(defines.events.script_raised_destroy, function(event)
	local entity = event.entity
	if has_layout(entity.name) then
		rebuild_factory(entity)
	elseif Connections.is_connectable(entity) then
		recheck_nearby_connections(entity, true) -- Delay
	elseif entity.type == "electric-pole" then
		Electricity.power_pole_destroyed(entity)
	end
end)

-- How to clone your factory
-- This implementation will not actually clone factory buildings, but move them to where they were cloned.
local clone_forbidden_prefixes = {
	"factory-1-",
	"factory-2-",
	"factory-3-",
	"factory-power-input-",
	"factory-connection-indicator-",
	"factory-power-pole",
	"factory-overlay-controller",
	"factory-port-marker",
	"factory-fluid-dummy-connector-"
}

local function is_entity_clone_forbidden(name)
	for _, prefix in pairs(clone_forbidden_prefixes) do
		if name:sub(1, #prefix) == prefix then
			return true
		end
	end
	return false
end

script.on_event(defines.events.on_entity_cloned, function(event)
	local src_entity = event.source
	local dst_entity = event.destination
	if is_entity_clone_forbidden(dst_entity.name) then
		dst_entity.destroy()
	elseif has_layout(src_entity.name) then
		local factory = get_factory_by_building(src_entity)
		cleanup_factory_exterior(factory, src_entity)
		if src_entity.valid then src_entity.destroy() end
		create_factory_exterior(factory, dst_entity)
	end
end)

-- ON TICK --

CONNECTION_UPDATE_RATE = 5
script.on_nth_tick(CONNECTION_UPDATE_RATE, Connections.update)

script.on_nth_tick(180, function(event)
	local has_players = {}
	for _, player in pairs(game.players) do
		if storage.surface_factories[player.surface_index] and (player.render_mode == defines.render_mode.chart or player.render_mode == defines.render_mode.chart_zoomed_in) then
			has_players[player.surface.name] = true
		end
	end
end)

-- CONNECTION SETTINGS --

script.on_event(defines.events.on_player_rotated_entity, function(event)
	local entity = event.entity
	if Connections.indicator_names[entity.name] then
		entity.direction = event.previous_direction
	elseif Connections.is_connectable(entity) then
		recheck_nearby_connections(entity)
		if entity.valid and entity.type == "underground-belt" then
			local neighbour = entity.neighbours
			if neighbour then
				recheck_nearby_connections(neighbour)
			end
		end
	end
end)

script.on_event("factory-rotate", function(event)
	local player = game.players[event.player_index]
	local entity = player.selected
	if not entity then return end
	if has_layout(entity.name) then
		local factory = get_factory_by_building(entity)
		if factory then --and player.is_cursor_empty() then
			toggle_port_markers(factory)
		end
	elseif Connections.indicator_names[entity.name] then
		local factory = find_surrounding_factory(entity.surface, entity.position)
		if factory then
			Connections.rotate(factory, entity)
		end
	end
end)

script.on_event("factory-increase", function(event)
	local entity = game.players[event.player_index].selected
	if not entity then return end
	if Connections.indicator_names[entity.name] then
		local factory = find_surrounding_factory(entity.surface, entity.position)
		if factory then
			Connections.adjust(factory, entity, true)
		end
	end
end)

script.on_event("factory-decrease", function(event)
	local entity = game.players[event.player_index].selected
	if not entity then return end
	if Connections.indicator_names[entity.name] then
		local factory = find_surrounding_factory(entity.surface, entity.position)
		if factory then
			Connections.adjust(factory, entity, false)
		end
	end
end)

-- MISC --

update_hidden_techs = function(force)
	if settings.global["Factorissimo2-hide-recursion"] and settings.global["Factorissimo2-hide-recursion"].value then
		force.technologies["factory-recursion-t1"].enabled = false
		force.technologies["factory-recursion-t2"].enabled = false
	elseif settings.global["Factorissimo2-hide-recursion-2"] and settings.global["Factorissimo2-hide-recursion-2"].value then
		force.technologies["factory-recursion-t1"].enabled = true
		force.technologies["factory-recursion-t2"].enabled = false
	else
		force.technologies["factory-recursion-t1"].enabled = true
		force.technologies["factory-recursion-t2"].enabled = true
	end
end

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	local setting = event.setting
	if setting == "Factorissimo2-hide-recursion" or setting == "Factorissimo2-hide-recursion-2" then
		for _, force in pairs(game.forces) do
			update_hidden_techs(force)
		end
	elseif setting == "Factorissimo2-indestructible-buildings" then
		for _, factory in pairs(storage.factories) do
			update_destructible(factory)
		end
	end
end)

script.on_event(defines.events.on_force_created, function(event)
	local force = event.force
	update_hidden_techs(force)
end)

script.on_event(defines.events.on_forces_merging, function(event)
	for _, factory in pairs(storage.factories) do
		if not factory.force.valid then
			factory.force = game.forces["player"]
		end
		if factory.force.name == event.source.name then
			factory.force = event.destination
		end
	end
end)

activate_factories = function()
	for _, factory in pairs(storage.factories) do
		factory.inactive = factory.outside_surface.valid and not can_place_factory_here(
			factory.layout.tier,
			factory.outside_surface,
			{x = factory.outside_x, y = factory.outside_y}
		)

		build_factory_upgrades(factory)
	end
end

script.on_event({defines.events.on_research_finished, defines.events.on_research_reversed}, function(event)
	if not storage.factories then return end -- In case any mod or scenario script calls LuaForce.research_all_technologies() during its on_init
	local research = event.research
	local name = research.name
	if name == "factory-connection-type-fluid" or name == "factory-connection-type-chest" or name == "factory-connection-type-circuit" then
		for _, factory in pairs(storage.factories) do
			if factory.built then Connections.recheck_factory(factory, nil, nil) end
		end
	elseif name == "factory-interior-upgrade-lights" then
		for _, factory in pairs(storage.factories) do Lights.build_lights_upgrade(factory) end
	elseif name == "factory-interior-upgrade-display" then
		for _, factory in pairs(storage.factories) do Overlay.build_display_upgrade(factory) end
	elseif name == "factory-interior-upgrade-roboport" then
		for _, factory in pairs(storage.factories) do Roboport.build_roboport_upgrade(factory) end
	elseif name == "factory-upgrade-greenhouse" then
		for _, factory in pairs(storage.factories) do Greenhouse.build_greenhouse_upgrade(factory) end
	elseif name == "factory-recursion-t1" or name == "factory-recursion-t2" then
		activate_factories()
	elseif name == "factory-preview" then
		for _, player in pairs(game.players) do Camera.get_camera_toggle_button(player) end
	end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if event.setting_type == "runtime-global" then activate_factories() end
end)

remote.add_interface("factorissimo", remote_api)
