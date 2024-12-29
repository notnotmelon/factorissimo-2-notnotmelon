remote_api = {}

BUILDING_TYPE = "storage-tank"

--[[
factory = {
	+id = *,
	(+)inactive = *,

	+outside_surface = *,
	+outside_x = *,
	+outside_y = *,
	+outside_door_x = *,
	+outside_door_y = *,

	+inside_surface = *,
	+inside_x = *,
	+inside_y = *,
	+inside_door_x = *,
	+inside_door_y = *,

	+force = *,
	+layout = *,
	+building = *,
	+outside_energy_receiver = *,
	+outside_overlay_displays = {*},
	+outside_port_markers = {*},

	+inside_overlay_controller = *,
	+_inside_power_pole = *,

	+stored_pollution = *,

	+connections = {*},
	+connection_settings = {{*}*},
	+connection_indicators = {*},

	+upgrades = {},
}
]] --

remote_api.get_factory_by_entity = function(entity)
    if entity == nil then return nil end
    return storage.factories_by_entity[entity.unit_number]
end

remote_api.get_factory_by_building = function(entity)
    local factory = storage.factories_by_entity[entity.unit_number]
    if factory == nil then
        game.print("ERROR: Unbound factory building: " .. entity.name .. "@" .. entity.surface.name .. "(" .. entity.position.x .. ", " .. entity.position.y .. ")")
    end
    return factory
end

remote_api.find_factory_by_area = function(params)
    local surface = params.surface
    local position = params.position
    local area = params.area

    for _, entity in pairs(surface.find_entities_filtered {position = position, area = area, type = BUILDING_TYPE}) do
        if factorissimo.has_layout(entity.name) then return remote_api.get_factory_by_building(entity) end
    end
    return nil
end

remote_api.find_factories_by_area = function(params)
    local surface = params.surface
    local area = params.area

    local factories = {}
    for _, entity in pairs(surface.find_entities_filtered {area = area, type = BUILDING_TYPE}) do
        if factorissimo.has_layout(entity.name) then
            local factory = remote_api.get_factory_by_building(entity)
            if factory then factories[#factories + 1] = factory end
        end
    end
    return factories
end

remote_api.find_surrounding_factory = function(surface, position)
    local factories = storage.surface_factories[surface.index]
    if factories == nil then return nil end
    local x = math.floor(0.5 + position.x / (16 * 32))
    local y = math.floor(0.5 + position.y / (16 * 32))
    if (x > 7 or x < 0) then return nil end
    return factories[8 * y + x + 1]
end

remote_api.find_surrounding_factory_by_surface_index = function(surface_index, position)
    local factories = storage.surface_factories[surface_index]
    if factories == nil then return nil end
    local x = math.floor(0.5 + position.x / (16 * 32))
    local y = math.floor(0.5 + position.y / (16 * 32))
    if (x > 7 or x < 0) then return nil end
    return factories[8 * y + x + 1]
end

remote.add_interface("factorissimo", remote_api)

return remote_api
