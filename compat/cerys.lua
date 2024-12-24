Compat = Compat or {}

local function spawn_radiative_tower(surface, x, y)
    local e = surface.create_entity {
        name = "cerys-fulgoran-radiative-tower-contracted-container",
        position = {x, y},
        force = "neutral",
    }

    if not e or not e.valid then return end

    e.minable_flag = false
    e.destructible = false

    local inv = e.get_inventory(defines.inventory.chest)
    if inv and inv.valid then
        inv.insert {name = "iron-stick", count = 1}
    end

    -- radiative_towers.register_heating_tower_contracted(e)
end

local function spawn_cryogenic_plant(surface, x, y)
    local e = surface.create_entity {
        name = "cerys-fulgoran-cryogenic-plant-wreck-frozen",
        position = {x, y},
        force = "player",
    }

    if e and e.valid then
        e.minable_flag = false
        e.destructible = false
        -- repair.register_ancient_cryogenic_plant(e, true)
    end
end

local DEFAULT_CERYS_TOWER_POSITIONS = {
    {-10, 10},
    {10,  10},
    {10,  -10},
    {-10, -10},
}

Compat.spawn_cerys_entities = function(factory)
    if not script.active_mods["Cerys-Moon-of-Fulgora"] then return end

    local surface = factory.inside_surface
    if surface.name ~= "cerys-factory-floor" then return end
    local x, y = factory.inside_x, factory.inside_y

    for _, tower_position in pairs(factory.layout.radiative_towers or DEFAULT_CERYS_TOWER_POSITIONS) do
        spawn_radiative_tower(surface, x + tower_position[1], y + tower_position[2])
    end
    spawn_cryogenic_plant(surface, x, y)
end