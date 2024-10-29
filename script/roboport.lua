Roboport = {}

local function set_default_roboport_construction_robot_request(roboport)
    -- https://forums.factorio.com/viewtopic.php?f=28&t=118245
    return roboport.surface.create_entity {
        name = "item-request-proxy",
        position = roboport.position,
        target = roboport,
        modules = {{
            id = {
                name = "construction-robot",
                quality = roboport.quality.name
            },
            items = {
                in_inventory = {
                    {inventory = defines.inventory.roboport_robot, stack = 0, count = 10}
                }
            }
        }},
        force = roboport.force
    }
end

Roboport.build_roboport_upgrade = function(factory)
    if not factory.inside_surface.valid or not factory.outside_surface.valid then return end

    local requester = factory.roboport_upgrade and factory.roboport_upgrade.requester and factory.roboport_upgrade.requester.valid and factory.roboport_upgrade.requester
    local roboport = factory.roboport_upgrade and factory.roboport_upgrade.roboport.valid and factory.roboport_upgrade.roboport
    local storage = factory.roboport_upgrade and factory.roboport_upgrade.storage.valid and factory.roboport_upgrade.storage

    if factory.building and factory.building.valid then
        requester = requester or factory.outside_surface.create_entity {
            name = factory.layout.outside_requester_chest_type,
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
    local inital_ten_robot_request = set_default_roboport_construction_robot_request(roboport)
    storage = storage or factory.inside_surface.create_entity {
        name = "factory-construction-chest",
        position = {-factory.layout.overlays.inside_x + factory.inside_x, factory.layout.overlays.inside_y + factory.inside_y},
        force = factory.force,
        quality = factory.quality,
    }

    for _, entity in pairs {roboport, storage, requester} do
        entity.destructible = false
        entity.minable = false
        entity.rotatable = false
    end

    factory.roboport_upgrade = {
        roboport = roboport,
        storage = storage,
        requester = requester,
        inital_ten_robot_request = inital_ten_robot_request,
        item_request_proxies = (factory.roboport_upgrade and factory.roboport_upgrade.item_request_proxies) or {}
    }
end

Roboport.cleanup_factory_exterior = function(factory)
    local requester = factory.roboport_upgrade and factory.roboport_upgrade.requester.valid and factory.roboport_upgrade.requester
    if not requester then return end
    local surface = requester.surface

    local inventory = requester.get_inventory(defines.inventory.chest)
    for i = 1, #inventory do
        local stack = inventory[i]
        if stack.valid_for_read then
            surface.spill_item_stack(requester.position, stack)
        end
    end
    requester.destroy()
    factory.roboport_upgrade.item_request_proxies = {}
end

local GHOST_PROTOTYPE_NAME = "entity-ghost"
local function get_construction_requests_by_factory()
    local missing_ghosts_per_factory = {}

    for surface_index, factories in pairs(storage.surface_factories) do
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
                local factory = remote_api.find_surrounding_factory_by_surface_index(surface_index, ghost.position)
                if not factory.roboport_upgrade then goto continue end
                if not factory.built or not factory.building.valid then goto continue end
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
    end

    local construction_requests_by_factory = {}
    for factory, missing_ghosts in pairs(missing_ghosts_per_factory) do
        local requests_by_itemname = {}
        for _, ghost in pairs(missing_ghosts) do
            local items_to_place
            if ghost.name == GHOST_PROTOTYPE_NAME then
                items_to_place = ghost.ghost_prototype.items_to_place_this -- collect all items_to_place_this for construction ghosts
            else
                items_to_place = ghost.item_requests -- items can also be delived to the `item-request-proxy` prototype
            end

            for _, item_to_place in pairs(items_to_place) do
                local item_name = item_to_place.name
                requests_by_itemname[item_name] = requests_by_itemname[item_name] or {}
                local requests_by_quality = requests_by_itemname[item_name]
                local quality = item_to_place.quality or ghost.quality.name
                requests_by_quality[quality] = requests_by_quality[quality] or 0
                requests_by_quality[quality] = requests_by_quality[quality] + item_to_place.count
            end
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

script.on_nth_tick(157, function()
    local construction_requests_by_factory = get_construction_requests_by_factory()

    -- update each factory and create item-request-proxy for unfulfilled construction requests
    for _, factory in pairs(storage.factories) do
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
end)

create_or_remove_item_request_proxies = function(factory, requests_by_itemname)
    local roboport_upgrade = factory.roboport_upgrade

    local requester = roboport_upgrade.requester
    if not requester.valid then return end

    for _, already_has in pairs(requester.get_inventory(defines.inventory.chest).get_contents()) do
        local name, quality = already_has.name, already_has.quality -- subtract off all the items we already have in storage
        if requests_by_itemname[name] and requests_by_itemname[name][quality] then
            requests_by_itemname[name][quality] = requests_by_itemname[name][quality] - already_has.count
            if requests_by_itemname[name][quality] <= 0 then
                requests_by_itemname[name][quality] = nil
            end
        end
    end

    local already_occupied_inventory_indexes = {}
    local proxies = {}
    for _, proxy in pairs(roboport_upgrade.item_request_proxies) do
        if proxy.valid then
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
    end
    
    roboport_upgrade.item_request_proxies = proxies

    create_new_item_request_proxies(factory, requests_by_itemname, already_occupied_inventory_indexes)
end

create_new_item_request_proxies = function(factory, requests_by_itemname, already_occupied_inventory_indexes)
    local roboport_upgrade = factory.roboport_upgrade
    local requester = roboport_upgrade.requester
    local requester_inventory = requester.get_inventory(defines.inventory.chest)

    -- "modules" is the name of the list of all items to be requested by the item request proxy.
    -- it has nothing to do with modules this is a legacy name from 1.1
    local modules = {}
    
    for item_name, requests_by_quality in pairs(requests_by_itemname) do
        for quality, count in pairs(requests_by_quality) do
            while count > 0 do
                local next_available_inventory_slot
                for i = 1, #requester_inventory do
                    if not already_occupied_inventory_indexes[i] and not requester_inventory[i].valid_for_read then
                        next_available_inventory_slot = i
                        already_occupied_inventory_indexes[i] = true
                        break
                    end
                end
                if not next_available_inventory_slot then goto no_more_inventory_space end

                local insertion_count = math.min(count, prototypes.item[item_name].stack_size)
                count = count - insertion_count
                
                local module = {
                    id = {
                        name = item_name,
                        quality = quality,
                    },
                    items = {
                        in_inventory = {{inventory = defines.inventory.chest, stack = next_available_inventory_slot - 1, count = insertion_count}}
                    }
                }

                modules[#modules + 1] = module
            end
        end
    end

    ::no_more_inventory_space::
    if not next(modules) then return end

    local proxies = roboport_upgrade.item_request_proxies
    proxies[#proxies + 1] = factory.outside_surface.create_entity {
        name = "item-request-proxy",
        position = requester.position,
        target = requester,
        modules = modules,
        force = requester.force
    }
end

-- smaller update function to transfer items from the requester chest to the construction chest
script.on_nth_tick(43, function()
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
        local robot_inventory = roboport.get_inventory(defines.inventory.roboport_robot)
        local needs_robots = robot_inventory.is_empty()
        local storage_inventory = storage.get_inventory(defines.inventory.chest)

        for i = 1, #requester_inventory do
            local stack = requester_inventory[i]
            if stack.valid_for_read then
                if needs_robots then
                    local amount_moved = robot_inventory.insert(stack)
                    if amount_moved > 0 then
                        stack.count = stack.count - amount_moved
                        needs_robots = false
                        roboport_upgrade.inital_ten_robot_request.destroy()
                        goto inserted_some_robots
                    end
                end
                local amount_moved = storage_inventory.insert(stack)
                if amount_moved > 0 then
                    stack.count = stack.count - amount_moved
                end
                ::inserted_some_robots::
            end
        end

        ::continue::
    end
end)