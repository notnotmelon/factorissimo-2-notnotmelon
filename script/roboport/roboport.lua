local blacklisted_names = require "script.roboport.blacklist"
local utility_constants = require "script.roboport.utility-constants"

factorissimo.on_event(factorissimo.events.on_init(), function()
    storage.construction_robots = storage.construction_robots or {}
    storage.lock = storage.lock or {}
    storage.deathrattles = storage.deathrattles or {}
    storage.tasks_at_tick = storage.tasks_at_tick or {}
end)

factorissimo.on_event(defines.events.on_object_destroyed, function(event)
    local deathrattle = storage.deathrattles[event.registration_number]
    if not deathrattle then return end
    storage.deathrattles[event.registration_number] = nil
    if not deathrattle.network_id then return end
    storage.networkdata[deathrattle.network_id] = nil
end)

local function add_task(tick, task)
    local tasks_at_tick = storage.tasks_at_tick[tick]
    if tasks_at_tick then
        tasks_at_tick[#tasks_at_tick + 1] = task
    else
        storage.tasks_at_tick[tick] = {task}
    end
end

local function get_tilebox(bounding_box)
    local left_top = bounding_box.left_top
    local right_bottom = bounding_box.right_bottom
    -- expand the bounding_box to the nearest integer
    left_top.x = math.floor(left_top.x)
    left_top.y = math.floor(left_top.y)
    right_bottom.x = math.ceil(right_bottom.x)
    right_bottom.y = math.ceil(right_bottom.y)

    local positions = {}

    local i = 1
    for y = left_top.y, right_bottom.y - 1 do
        for x = left_top.x, right_bottom.x - 1 do
            positions[i] = {x = x, y = y}
            i = i + 1
        end
    end

    return positions
end

-- position is expected to have a .5 decimal
local function get_piece(position, center)
    if position.x > center.x then
        return position.y < center.y and "back_right" or "front_right"
    else
        return position.y < center.y and "back_left" or "front_left"
    end
end

local function is_back_piece(piece)
    return piece == "back_left" or piece == "back_right"
end

local function get_manhattan_distance(position, center)
    local delta_x = position.x - center.x
    local delta_y = position.y - center.y

    return math.abs(delta_x) + math.abs(delta_y)
end

local function get_build_sound_path(selection_box)
    local area = (selection_box.right_bottom.x - selection_box.left_top.x) * (selection_box.right_bottom.y - selection_box.left_top.y)

    if area < utility_constants.small_area_size then return "utility/build_animated_small" end
    if area < utility_constants.medium_area_size then return "utility/build_animated_medium" end
    if area < utility_constants.large_area_size then return "utility/build_animated_large" end

    return "utility/build_animated_huge"
end

local TICKS_PER_FRAME = 2
local FRAMES_BEFORE_BUILT = 16
local FRAMES_BETWEEN_BUILDING = 8 * 2
local FRAMES_BETWEEN_REMOVING = 4

local function request_platform_animation_for(entity)
    if entity.name ~= "entity-ghost" then return end
    if blacklisted_names[entity.ghost_name] then return end
    if storage.lock[entity.unit_number] then return end

    local tick = game.tick
    local surface = entity.surface

    surface.play_sound {
        path = get_build_sound_path(entity.selection_box),
        position = entity.position,
    }

    local tilebox = get_tilebox(entity.bounding_box)
    local largest_manhattan_distance = 0
    for _, position in ipairs(tilebox) do
        position.center = {x = position.x + 0.5, y = position.y + 0.5}
        position.manhattan_distance = get_manhattan_distance(position.center, entity.position)

        if position.manhattan_distance > largest_manhattan_distance then
            largest_manhattan_distance = position.manhattan_distance
        end
    end

    local remove_scaffold_delay = (largest_manhattan_distance + 4) * FRAMES_BETWEEN_BUILDING
    local all_scaffolding_down_at = tick + 1 + largest_manhattan_distance * FRAMES_BETWEEN_REMOVING + remove_scaffold_delay + 16 * TICKS_PER_FRAME

    -- by putting a colliding entity in the center of the building site we'll force the construction robot to wait (between that tick and a second)
    local all_scaffolding_up_at = tick + 1 + largest_manhattan_distance * FRAMES_BETWEEN_BUILDING + 15 * TICKS_PER_FRAME
    add_task(all_scaffolding_up_at, {
        name = "destroy",
        entity = surface.create_entity {
            name = "ghost-being-constructed",
            force = "neutral",
            position = entity.position,
            create_build_effect_smoke = false,
            preserve_ghosts_and_corpses = true,
        }
    })

    for _, position in ipairs(tilebox) do
        local piece = get_piece(position.center, entity.position)
        local animations = {} -- local animations = {} -- top & body

        local up_base = tick + 1 + position.manhattan_distance * FRAMES_BETWEEN_BUILDING
        add_task(up_base + 00 * TICKS_PER_FRAME, {name = "start", animations = animations})
        add_task(up_base + 15 * TICKS_PER_FRAME, {name = "pause", offset = 15, animations = animations})

        local down_base = tick + 1 + position.manhattan_distance * FRAMES_BETWEEN_REMOVING + remove_scaffold_delay
        add_task(down_base + 00 * TICKS_PER_FRAME, {name = "unpause", offset = 16, animations = animations})

        local ttl = down_base - tick + 16 * TICKS_PER_FRAME

        animations[1] = rendering.draw_animation {
            target = position.center,
            surface = surface,
            animation = "platform_entity_build_animations-" .. piece .. "-top",
            time_to_live = ttl,
            animation_offset = 0,
            animation_speed = 0,
            render_layer = entity.ghost_type == "cargo-landing-pad" and "above-inserters" or "higher-object-above",
            visible = false,
        }

        animations[2] = rendering.draw_animation {
            target = position.center,
            surface = surface,
            animation = "platform_entity_build_animations-" .. piece .. "-body",
            time_to_live = ttl,
            animation_offset = 0,
            animation_speed = 0,
            render_layer = is_back_piece(piece) and "lower-object-above-shadow" or "object",
            visible = false,
        }
    end

    storage.lock[entity.unit_number] = true
    add_task(all_scaffolding_down_at, {name = "unlock", unit_number = entity.unit_number})
end

local function do_tasks_at_tick(tick)
    local tasks_at_tick = storage.tasks_at_tick[tick]
    if tasks_at_tick then
        storage.tasks_at_tick[tick] = nil
        for _, task in ipairs(tasks_at_tick) do
            if task.name == "start" then
                local offset = -(tick * 0.5) % 32
                task.animations[1].visible = true
                task.animations[2].visible = true
                task.animations[1].animation_speed = 1
                task.animations[2].animation_speed = 1
                task.animations[1].animation_offset = offset
                task.animations[2].animation_offset = offset
            elseif task.name == "pause" then
                task.animations[1].animation_speed = 0
                task.animations[2].animation_speed = 0
                task.animations[1].animation_offset = task.offset
                task.animations[2].animation_offset = task.offset
            elseif task.name == "unpause" then
                local offset = -(tick * 0.5) % 32
                task.animations[1].animation_speed = 1
                task.animations[2].animation_speed = 1
                task.animations[1].animation_offset = offset + task.offset
                task.animations[2].animation_offset = offset + task.offset
            elseif task.name == "destroy" then
                task.entity.destroy()
            elseif task.name == "unlock" then
                storage.lock[task.unit_number] = nil
            end
        end
    end
end

factorissimo.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id ~= "factory-hidden-construction-robot-created" then return end

    local construction_robot = event.target_entity
    assert(construction_robot and construction_robot.name == "factory-hidden-construction-robot")

    -- ensure we are actually in a factory floor. prevent contraband construction robots from being created
    local surface_name = construction_robot.surface.name
    if not surface_name:find("%-factory%-floor$") and not surface_name:find("^factory%-floor%-%d+$") then
        add_task(game.tick + 1, {name = "destroy", entity = construction_robot}) -- delay this by a tick to avoid a crash
        return
    end

    storage.construction_robots[construction_robot.unit_number] = construction_robot
end)

factorissimo.on_event(defines.events.on_tick, function(event)
    for unit_number, entity in pairs(storage.construction_robots) do
        if entity.valid then
            local robot_order_queue = entity.robot_order_queue
            local this_order = robot_order_queue[1]

            if this_order and this_order.target then -- target can sometimes be optional
                if this_order.type == defines.robot_order_type.construct then
                    request_platform_animation_for(this_order.target)
                    --entity.destroy()
                end
            end
        else
            storage.construction_robots[unit_number] = nil
        end
    end

    do_tasks_at_tick(event.tick)
end)

factorissimo.build_roboport_upgrade = function(factory)
    if not factory.inside_surface.valid or not factory.outside_surface.valid then return end
    local force = factory.force
    if not force.valid then return end
    if not force.technologies["factory-interior-upgrade-roboport"].researched then return end

    local requester = factory.roboport_upgrade and factory.roboport_upgrade.requester and factory.roboport_upgrade.requester.valid and factory.roboport_upgrade.requester
    local roboport = factory.roboport_upgrade and factory.roboport_upgrade.roboport and factory.roboport_upgrade.roboport.valid and factory.roboport_upgrade.roboport
    local storage = factory.roboport_upgrade and factory.roboport_upgrade.storage and factory.roboport_upgrade.storage.valid and factory.roboport_upgrade.storage
    local hidden_roboport = factory.roboport_upgrade and factory.roboport_upgrade.hidden_roboport and factory.roboport_upgrade.hidden_roboport.valid and factory.roboport_upgrade.hidden_roboport

    if factory.building and factory.building.valid then
        requester = requester or factory.outside_surface.create_entity {
            name = factory.layout.outside_requester_chest_type or "factory-requester-chest-factory-3",
            position = factory.building.position,
            force = factory.force,
            quality = factory.quality,
        }
    else
        requester = nil
    end
    roboport = roboport or factory.inside_surface.create_entity {
        name = "factory-construction-roboport",
        position = {-factory.layout.inside_energy_x + factory.inside_x, factory.layout.inside_energy_y + factory.inside_y},
        force = factory.force,
        quality = factory.quality,
    }
    roboport.backer_name = ""

    hidden_roboport = hidden_roboport or factory.inside_surface.create_entity {
        name = "factory-hidden-construction-roboport",
        position = roboport.position,
        force = factory.force,
    }
    hidden_roboport.backer_name = ""
    hidden_roboport.get_inventory(defines.inventory.roboport_robot).insert {name = "factory-hidden-construction-robot", count = 500}

    storage = storage or factory.inside_surface.create_entity {
        name = "factory-construction-chest",
        position = {-factory.layout.overlays.inside_x + factory.inside_x, factory.layout.overlays.inside_y + factory.inside_y},
        force = factory.force,
        quality = factory.quality,
    }

    for _, entity in pairs {roboport, storage, requester, hidden_roboport} do
        entity.destructible = false
        entity.minable = false
        entity.rotatable = false
    end

    factory.roboport_upgrade = {
        roboport = roboport,
        storage = storage,
        requester = requester,
        hidden_roboport = hidden_roboport,
        item_request_proxies = (factory.roboport_upgrade and factory.roboport_upgrade.item_request_proxies) or {}
    }
end

factorissimo.cleanup_factory_exterior = function(factory)
    local requester = factory.roboport_upgrade and factory.roboport_upgrade.requester and factory.roboport_upgrade.requester.valid and factory.roboport_upgrade.requester
    if not requester then return end
    local surface = requester.surface

    local inventory = requester.get_inventory(defines.inventory.chest)
    for i = 1, #inventory do
        local stack = inventory[i]
        if stack.valid_for_read then
            surface.spill_item_stack {
                position = requester.position,
                stack = stack,
                enable_looted = true,
                force = requester.force_index,
                allow_belts = false,
                use_start_position_on_failure = true,
            }
        end
    end
    requester.destroy()
    factory.roboport_upgrade.item_request_proxies = {}
end

local GHOST_PROTOTYPE_NAME = "entity-ghost"
local TILE_GHOST_PROTOTYPE_NAME = "tile-ghost"

local function get_construction_requests_by_factory()
    local missing_ghosts_per_factory = {}

    for surface_index, factories in pairs(storage.surface_factories) do
        if not game.get_surface(surface_index) then goto invalid_surface end

        local forces_to_check = {}
        for _, factory in pairs(factories) do
            local force = factory.force
            if force.valid and not forces_to_check[force.index] and force.technologies["factory-interior-upgrade-roboport"].researched then
                -- theres no API function to get the current construction requests
                -- so instead we are reading it from the player's alerts! (this is a bad idea)
                -- find a valid online player to check the alerts for
                -- yes this means the roboport construction feature only works if you are logged in! too bad
                local _, player = next(force.connected_players)
                if player then forces_to_check[force.index] = player end
            end
        end

        for _, player in pairs(forces_to_check) do
            local missing = (player.get_alerts {
                type = defines.alert_type.no_material_for_construction,
                surface = surface_index,
            }[surface_index] or {})[defines.alert_type.no_material_for_construction] or {}
            for _, ghost in pairs(missing) do
                ghost = ghost.target
                if not ghost then goto continue end -- this can happen if the alerts are not updated yet but the entity is invalid
                --if ghost.is_registered_for_construction() then goto continue end -- we only care about ghosts that are not already being constructed
                local factory = remote_api.find_surrounding_factory_by_surface_index(surface_index, ghost.position)
                if not factory or not factory.roboport_upgrade then goto continue end
                if factory.inactive or not factory.built or not factory.building.valid then goto continue end
                if not factory.inside_surface.valid or not factory.outside_surface.valid then goto continue end

                local missing_ghosts = missing_ghosts_per_factory[factory]
                if missing_ghosts then
                    missing_ghosts[#missing_ghosts + 1] = ghost
                else
                    missing_ghosts_per_factory[factory] = {ghost}
                end

                ::continue::
            end
        end

        ::invalid_surface::
    end

    local construction_requests_by_factory = {}
    for factory, missing_ghosts in pairs(missing_ghosts_per_factory) do
        local requests_by_itemname = {}
        for _, ghost in pairs(missing_ghosts) do
            local items_to_place
            if ghost.name == GHOST_PROTOTYPE_NAME or ghost.name == TILE_GHOST_PROTOTYPE_NAME then
                items_to_place = ghost.ghost_prototype.items_to_place_this -- collect all items_to_place_this for construction ghosts
            elseif ghost.type == "item-request-proxy" then
                items_to_place = ghost.item_requests           -- items can also be delived to the `item-request-proxy` prototype
            elseif ghost.to_be_upgraded() then
                local upgrade_target, quality = ghost.get_upgrade_target()
                items_to_place = upgrade_target.items_to_place_this -- collect all items_to_place_this for upgrade planner ghosts
                for _, item in pairs(items_to_place) do item.quality = quality.name end
            else
                goto continue
            end

            for _, item_to_place in pairs(items_to_place) do
                local item_name = item_to_place.name
                requests_by_itemname[item_name] = requests_by_itemname[item_name] or {}
                local requests_by_quality = requests_by_itemname[item_name]
                local quality = item_to_place.quality or ghost.quality.name
                requests_by_quality[quality] = requests_by_quality[quality] or 0
                requests_by_quality[quality] = requests_by_quality[quality] + item_to_place.count
            end

            ::continue::
        end

        -- dont request instantiated factories. it already requests the raw factory item
        requests_by_itemname["factory-1-instantiated"] = nil -- hardcoding these is not ideal
        requests_by_itemname["factory-2-instantiated"] = nil
        requests_by_itemname["factory-3-instantiated"] = nil

        construction_requests_by_factory[factory] = requests_by_itemname
    end

    return construction_requests_by_factory
end

local create_or_remove_item_request_proxies -- function stub
local create_new_item_request_proxies       -- function stub

factorissimo.on_nth_tick(257, function()
    local construction_requests_by_factory = get_construction_requests_by_factory()

    -- update each factory and create item-request-proxy for unfulfilled construction requests
    for _, factory in pairs(storage.factories) do
        if not factory.inactive and factory.built then
            local requests_by_itemname = construction_requests_by_factory[factory]
            if requests_by_itemname then
                create_or_remove_item_request_proxies(factory, requests_by_itemname)
            elseif factory.roboport_upgrade and next(factory.roboport_upgrade.item_request_proxies) then
                for _, proxy in pairs(factory.roboport_upgrade.item_request_proxies) do
                    proxy.destroy()
                end
                factory.roboport_upgrade.item_request_proxies = {}
            end
        end
    end
end)

create_or_remove_item_request_proxies = function(factory, requests_by_itemname)
    local roboport_upgrade = factory.roboport_upgrade

    local requester = roboport_upgrade.requester
    if not requester.valid then return end
    local storage = roboport_upgrade.storage
    if not storage.valid then return end

    for _, chest in pairs {requester, storage} do
        for _, already_has in pairs(chest.get_inventory(defines.inventory.chest).get_contents()) do
            local name, quality = already_has.name, already_has.quality -- subtract off all the items we already have in storage
            if requests_by_itemname[name] then
                requests_by_itemname[name][quality] = nil
            end
        end
    end

    local already_occupied_inventory_indexes = {}
    local proxies = {}
    for _, proxy in pairs(roboport_upgrade.item_request_proxies) do
        if not proxy.valid then goto we_are_no_longer_requesting_this_item end

        local item_requests = proxy.item_requests
        for _, request in pairs(item_requests) do
            local name, quality = request.name, request.quality -- destroy any proxies that have their requests fulfilled already
            if not requests_by_itemname[name] or not requests_by_itemname[name][quality] then
                proxy.destroy()
                goto we_are_no_longer_requesting_this_item
            end
        end

        for _, request in pairs(item_requests) do
            local name, quality = request.name, request.quality -- same logic as above. subtract off all the items we are already requesting
            requests_by_itemname[name][quality] = nil

            for _, insert_plan in pairs(proxy.insert_plan) do
                for _, inventory_locator in pairs(insert_plan.items.in_inventory) do
                    -- inventory_locator.stack is 0-indexed for some reason. adjust.
                    already_occupied_inventory_indexes[inventory_locator.stack + 1] = true
                end
            end
        end

        proxies[#proxies + 1] = proxy
        ::we_are_no_longer_requesting_this_item::
    end

    roboport_upgrade.item_request_proxies = proxies

    create_new_item_request_proxies(factory, requests_by_itemname, already_occupied_inventory_indexes)
end

create_new_item_request_proxies = function(factory, requests_by_itemname, already_occupied_inventory_indexes)
    local roboport_upgrade = factory.roboport_upgrade
    local requester = roboport_upgrade.requester
    local requester_inventory = requester.get_inventory(defines.inventory.chest)

    for item_name, requests_by_quality in pairs(requests_by_itemname) do
        for quality, count in pairs(requests_by_quality) do
            local next_available_inventory_slot
            for i = 1, #requester_inventory do
                if not already_occupied_inventory_indexes[i] and not requester_inventory[i].valid_for_read then
                    next_available_inventory_slot = i
                    already_occupied_inventory_indexes[i] = true
                    break
                end
            end
            if not next_available_inventory_slot then return end

            count = math.min(count, prototypes.item[item_name].stack_size)

            local module = {
                id = {
                    name = item_name,
                    quality = quality,
                },
                items = {
                    in_inventory = {{inventory = defines.inventory.chest, stack = next_available_inventory_slot - 1, count = count}}
                }
            }

            local proxies = roboport_upgrade.item_request_proxies
            proxies[#proxies + 1] = factory.outside_surface.create_entity {
                name = "item-request-proxy",
                position = requester.position,
                target = requester,
                modules = {module},
                force = requester.force
            }
        end
    end
end

-- smaller update function to transfer items from the requester chest to the construction chest
factorissimo.on_nth_tick(43, function()
    for _, factory in pairs(storage.factories) do
        local roboport_upgrade = factory.roboport_upgrade
        if not roboport_upgrade then goto continue end
        local requester = roboport_upgrade.requester
        if not requester or not requester.valid then goto continue end
        local storage = roboport_upgrade.storage
        local roboport = roboport_upgrade.roboport
        if not storage.valid or not roboport.valid then goto continue end

        local requester_inventory = requester.get_inventory(defines.inventory.chest)
        if requester_inventory.is_empty() then goto continue end
        local storage_inventory = storage.get_inventory(defines.inventory.chest)

        for i = 1, #requester_inventory do
            local stack = requester_inventory[i]
            if stack.valid_for_read then
                stack.count = stack.count - storage_inventory.insert(stack)
            end
        end

        ::continue::
    end
end)

-- yet another update function to ensure the hidden roboport is always half filled.
factorissimo.on_nth_tick(367, function()
    for _, factory in pairs(storage.factories) do
        local roboport_upgrade = factory.roboport_upgrade
        if not roboport_upgrade then goto continue end
        local hidden_roboport = roboport_upgrade.hidden_roboport
        if not hidden_roboport or not hidden_roboport.valid then goto continue end
        local robot_inventory = hidden_roboport.get_inventory(defines.inventory.roboport_robot)

        robot_inventory.clear()
        robot_inventory.insert {name = "factory-hidden-construction-robot", count = 500}

        ::continue::
    end
end)

factorissimo.on_event(defines.events.on_gui_opened, function(event)
    local gui_type = event.gui_type
    if gui_type ~= defines.gui_type.entity then return end
    local entity = event.entity
    if not entity or not entity.valid then return end
    if entity.type ~= "roboport" then return end

    local robot_inventory = entity.get_inventory(defines.inventory.roboport_robot)
    robot_inventory.remove {name = "factory-hidden-construction-robot", count = 10000} -- bad! no contraband
end)
