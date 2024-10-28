Roboport = {}

--[[/c game.print(serpent.line(game.player.get_alerts{type=defines.alert_type.no_material_for_construction}))

game.player.surface.create_entity{
    name='item-request-proxy',
    position=game.player.selected.position,
    target=game.player.selected,
    modules={{
        id={
            name='iron-plate',
            quality='rare'
        },
        items={
            in_inventory={
                {inventory=defines.inventory.chest,stack=1,count=10}
            }
        }
    }},
    force=game.player.selected.force
}--]]

Roboport.build_roboport_upgrade = function(factory)
    local requester = factory.roboport_upgrade and factory.roboport_upgrade.requester.valid and factory.roboport_upgrade.requester
    local roboport = factory.roboport_upgrade and factory.roboport_upgrade.roboport.valid and factory.roboport_upgrade.roboport
    local storage = factory.roboport_upgrade and factory.roboport_upgrade.storage.valid and factory.roboport_upgrade.storage

    requester = requester or factory.outside_surface.create_entity {
        name = factory.layout.outside_requester_chest_type,
        position = factory.building.position,
        force = factory.force,
        quality = factory.quality,
    }
    roboport = roboport or factory.inside_surface.create_entity {
        name = "factory-construction-roboport",
        position = {-factory.layout.inside_energy_x + factory.inside_x, factory.layout.inside_energy_y + factory.inside_y},
        force = factory.force,
        quality = factory.quality,
    }
    storage = storage or factory.inside_surface.create_entity {
        name = "factory-construction-chest",
        position = {-factory.layout.overlays.inside_x + factory.inside_x, factory.layout.overlays.inside_y + factory.inside_y},
        force = factory.force,
        quality = factory.quality,
    }
    factory.roboport_upgrade = {roboport = roboport, storage = storage, requester = requester}

    for _, entity in pairs(factory.roboport_upgrade) do
        entity.destructible = false
        entity.minable = false
        entity.rotatable = false
    end
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
end

local function get_construction_requests_by_factory()
    local ghost_prototype = prototypes.entity["entity-ghost"]
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
                prototype = ghost_prototype
            }[surface_index] or {})[defines.alert_type.no_material_for_construction] or {}
            for _, ghost in pairs(missing) do
                ghost = ghost.target
                local factory = remote_api.find_surrounding_factory_by_surface_index(surface_index, ghost.position)
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
        local requests_by_quality = {}
        for _, ghost in pairs(missing_ghosts) do
            for _, item_to_place in pairs(ghost.ghost_prototype.items_to_place_this) do
                local quality = ghost.quality.name
                requests_by_quality[quality] = requests_by_quality[quality] or {}
                local requests_by_name = requests_by_quality[quality]
                local item_name = item_to_place.name
                requests_by_name[item_name] = requests_by_name[item_name] or 0
                requests_by_name[item_name] = requests_by_name[item_name] + item_to_place.count
            end
        end
        construction_requests_by_factory[factory] = requests_by_quality
    end

    for factory, requests in pairs(construction_requests_by_factory) do
        game.print(serpent.block(requests))
    end

    return construction_requests_by_factory
end

script.on_nth_tick(10 * 60, get_construction_requests_by_factory)
