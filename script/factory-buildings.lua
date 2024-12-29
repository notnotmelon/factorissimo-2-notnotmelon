local get_factory_by_building = remote_api.get_factory_by_building
local find_surrounding_factory = remote_api.find_surrounding_factory

local has_layout = factorissimo.has_layout

-- INITIALIZATION --

factorissimo.on_event(factorissimo.events.on_init(), function()
    -- List of all factories
    storage.factories = storage.factories or {}
    -- Map: Id from item-with-tags -> Factory
    storage.saved_factories = storage.saved_factories or {}
    -- Map: Entity unit number -> Factory it is a part of
    storage.factories_by_entity = storage.factories_by_entity or {}
    -- Map: Surface index -> list of factories on it
    storage.surface_factories = storage.surface_factories or {}
    -- Scalar
    storage.next_factory_surface = storage.next_factory_surface or 0
end)

-- RECURSION TECHNOLOGY --

local function does_original_planet_match_surface(original_planet, surface)
    if not original_planet then return true end
    if not original_planet.valid then return false end
    local original_planet_name = original_planet.surface.name:gsub("%-factory%-floor$", "")
    local surface_name = surface.name:gsub("%-factory%-floor$", "")
    return original_planet_name == surface_name
end

local function can_place_factory_here(tier, surface, position, original_planet)
    if not does_original_planet_match_surface(original_planet, surface) then
        local original_planet_name = original_planet.name:gsub("%-factory%-floor$", "")
        local original_planet_prototype = (game.planets[original_planet_name] or original_planet).prototype
        local flying_text = {"factory-connection-text.invalid-placement-planet", original_planet_name, original_planet_prototype.localised_name}
        factorissimo.create_flying_text {position = position, text = flying_text}
        return false
    end

    local factory = find_surrounding_factory(surface, position)
    if not factory then return true end
    local outer_tier = factory.layout.tier
    if outer_tier > tier and (factory.force.technologies["factory-recursion-t1"].researched or settings.global["Factorissimo2-free-recursion"].value) then return true end
    if (outer_tier >= tier or settings.global["Factorissimo2-better-recursion-2"].value)
        and (factory.force.technologies["factory-recursion-t2"].researched or settings.global["Factorissimo2-free-recursion"].value) then
        return true
    end
    if outer_tier > tier then
        factorissimo.create_flying_text {position = position, text = {"factory-connection-text.invalid-placement-recursion-1"}}
    elseif (outer_tier >= tier or settings.global["Factorissimo2-better-recursion-2"].value) then
        factorissimo.create_flying_text {position = position, text = {"factory-connection-text.invalid-placement-recursion-2"}}
    else
        factorissimo.create_flying_text {position = position, text = {"factory-connection-text.invalid-placement"}}
    end
    return false
end

local function build_factory_upgrades(factory)
    factorissimo.build_lights_upgrade(factory)
    factorissimo.build_greenhouse_upgrade(factory)
    factorissimo.build_display_upgrade(factory)
    factorissimo.build_roboport_upgrade(factory)
end

--- If a factory factory is built without proper recursion technology, it will be inactive.
--- This function reactivates these factories once the research is complete.
local function activate_factories()
    for _, factory in pairs(storage.factories) do
        factory.inactive = factory.outside_surface.valid and not can_place_factory_here(
            factory.layout.tier,
            factory.outside_surface,
            {x = factory.outside_x, y = factory.outside_y},
            factory.original_planet
        )

        build_factory_upgrades(factory)
    end
end
factorissimo.on_event(factorissimo.events.on_init(), activate_factories)

factorissimo.on_event({defines.events.on_research_finished, defines.events.on_research_reversed}, function(event)
    if not storage.factories then return end -- In case any mod or scenario script calls LuaForce.research_all_technologies() during its on_init
    local name = event.research.name
    if name == "factory-interior-upgrade-lights" then
        for _, factory in pairs(storage.factories) do factorissimo.build_lights_upgrade(factory) end
    elseif name == "factory-interior-upgrade-display" then
        for _, factory in pairs(storage.factories) do factorissimo.build_display_upgrade(factory) end
    elseif name == "factory-interior-upgrade-roboport" then
        for _, factory in pairs(storage.factories) do factorissimo.build_roboport_upgrade(factory) end
    elseif name == "factory-upgrade-greenhouse" then
        for _, factory in pairs(storage.factories) do factorissimo.build_greenhouse_upgrade(factory) end
    elseif name == "factory-recursion-t1" or name == "factory-recursion-t2" then
        activate_factories()
    end
end)

local function update_recursion_techs(force)
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

factorissimo.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting_type == "runtime-global" then activate_factories() end

    for _, force in pairs(game.forces) do
        update_recursion_techs(force)
    end
end)

factorissimo.on_event(defines.events.on_force_created, function(event)
    local force = event.force
    update_recursion_techs(force)
end)

factorissimo.on_event(factorissimo.events.on_init(), function()
    for _, force in pairs(game.forces) do
        update_recursion_techs(force)
    end
end)

-- FACTORY GENERATION --

local function update_destructible(factory)
    if factory.built and factory.building.valid then
        factory.building.destructible = not settings.global["Factorissimo2-indestructible-buildings"].value
    end
end

local function get_surface_name(layout, parent_surface)
    if factorissimo.surface_override then return factorissimo.surface_override end

    if parent_surface.planet then
        return (parent_surface.name .. "-factory-floor"):gsub("%-factory%-floor%-factory%-floor", "-factory-floor")
    end

    storage.next_factory_surface = storage.next_factory_surface + 1
    return storage.next_factory_surface .. "-factory-floor"
end

factorissimo.on_event(defines.events.on_surface_created, function(event)
    local surface = game.get_surface(event.surface_index)
    if not surface.name:find("%-factory%-floor$") then return end

    local mgs = surface.map_gen_settings
    mgs.width = 2
    mgs.height = 2
    surface.map_gen_settings = mgs
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
    factorissimo.spawn_maraxsis_water_shaders(surface, {x = cx, y = cy})

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

    factorissimo.get_or_create_inside_power_pole(factory)
    factorissimo.spawn_cerys_entities(factory)

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

    factorissimo.recheck_factory(factory, nil, nil)
    factorissimo.update_power_connection(factory)
    factorissimo.update_overlay(factory)
    update_destructible(factory)
    build_factory_upgrades(factory)
    return factory
end

local function cleanup_factory_exterior(factory, building)
    factorissimo.cleanup_factory_exterior(factory)
    factorissimo.cleanup_factory_exterior(factory)

    factorissimo.disconnect_factory(factory)
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

-- FACTORY MINING AND DECONSTRUCTION --

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
factorissimo.on_event({
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
    end
end)

local function prevent_factory_mining(entity)
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
    factorissimo.update_overlay(factory)
    if #factory.outside_port_markers ~= 0 then
        factory.outside_port_markers = {}
        toggle_port_markers(factory)
    end
    factorissimo.create_flying_text {position = entity.position, text = {"factory-cant-be-mined"}}
end

local fake_robots = {["repair-block-robot"] = true} -- Modded construction robots with heavy control scripting
factorissimo.on_event(defines.events.on_robot_pre_mined, function(event)
    local entity = event.entity
    if has_layout(entity.name) and fake_robots[event.robot.name] then
        prevent_factory_mining(entity)
        entity.destroy()
    elseif entity.type == "item-entity" and entity.stack.valid_for_read and has_layout(entity.stack.name) then
        event.robot.destructible = false
    end
end)

-- How biters pick up factories
-- Too bad they don't have hands
factorissimo.on_event(defines.events.on_entity_died, function(event)
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
    end
end)

factorissimo.on_event(defines.events.on_post_entity_died, function(event)
    if not has_layout(event.prototype.name) or not event.ghost then return end
    local factory = storage.factories_by_entity[event.unit_number]
    if not factory then return end
    event.ghost.tags = {id = factory.id}
end)

-- Just rebuild the factory in this case
factorissimo.on_event(defines.events.script_raised_destroy, function(event)
    local entity = event.entity
    if has_layout(entity.name) then
        prevent_factory_mining(entity)
    end
end)

-- FACTORY PLACEMENT AND INITALIZATION --

local function create_fresh_factory(entity)
    local layout = factorissimo.create_layout(entity.name, entity.quality)
    local factory = create_factory_interior(layout, entity)
    create_factory_exterior(factory, entity)
    factory.original_planet = entity.surface.planet
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
        factory.inactive = not can_place_factory_here(factory.layout.tier, entity.surface, entity.position, factory.original_planet)
        return
    end

    if not factory and storage.factories[tags.id] then
        -- This factory was copied from somewhere else. Clone all contained entities
        local factory = create_fresh_factory(entity)
        factorissimo.copy_entity_ghosts(storage.factories[tags.id], factory)
        factorissimo.update_overlay(factory)
        return
    end

    factorissimo.create_flying_text {position = entity.position, text = {"factory-connection-text.invalid-factory-data"}}
    entity.destroy()
end

factorissimo.on_event(factorissimo.events.on_built(), function(event)
    local entity = event.entity
    local entity_name = entity.name
    
    if has_layout(entity_name) then
        local inventory = event.consumed_items
        local tags = event.tags or (inventory and not inventory.is_empty() and inventory[1].valid_for_read and inventory[1].is_item_with_tags and inventory[1].tags) or nil
        handle_factory_placed(entity, tags)
        return
    end

    if entity.type ~= "entity-ghost" then return end
    local ghost_name = entity.ghost_name

    if has_layout(ghost_name) and entity.tags then
        local copied_from_factory = storage.factories[entity.tags.id]
        if copied_from_factory then
            factorissimo.update_overlay(copied_from_factory, entity)
        end
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

factorissimo.on_event(defines.events.on_entity_cloned, function(event)
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

-- MISC --

commands.add_command("give-lost-factory-buildings", {"command-help-message.give-lost-factory-buildings"}, function(event)
    local player = game.get_player(event.player_index)
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

factorissimo.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    local setting = event.setting
    if setting == "Factorissimo2-indestructible-buildings" then
        for _, factory in pairs(storage.factories) do
            update_destructible(factory)
        end
    end
end)

factorissimo.on_event(defines.events.on_forces_merging, function(event)
    for _, factory in pairs(storage.factories) do
        if not factory.force.valid then
            factory.force = game.forces["player"]
        end
        if factory.force.name == event.source.name then
            factory.force = event.destination
        end
    end
end)