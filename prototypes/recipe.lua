data:extend {
    -- Factory buildings
    {
        type = "recipe",
        name = "factory-1",
        enabled = false,
        energy_required = 30,
        ingredients = {
            {type = "item", name = "stone",        amount = 500},
            {type = "item", name = "iron-plate",   amount = 500},
            {type = "item", name = "copper-plate", amount = 200}
        },
        results = {{type = "item", name = "factory-1", amount = 1}},
        main_product = "factory-1",
        localised_name = {"entity-name.factory-1"},
        categories = data.raw["recipe-category"]["metallurgy"] and {"metallurgy", "crafting"} or nil
    },
    {
        type = "recipe",
        name = "factory-2",
        enabled = false,
        energy_required = 45,
        ingredients = {
            {type = "item", name = "stone-brick",       amount = 1000},
            {type = "item", name = "steel-plate",       amount = 250},
            {type = "item", name = "big-electric-pole", amount = 50}
        },
        results = {{type = "item", name = "factory-2", amount = 1}},
        main_product = "factory-2",
        localised_name = {"entity-name.factory-2"},
        categories = data.raw["recipe-category"]["metallurgy"] and {"metallurgy", "crafting"} or nil
    },
    {
        type = "recipe",
        name = "factory-3",
        enabled = false,
        energy_required = 60,
        ingredients = {
            {type = "item", name = "concrete",    amount = 5000},
            {type = "item", name = "steel-plate", amount = 2000},
            {type = "item", name = "substation",  amount = 100}
        },
        results = {{type = "item", name = "factory-3", amount = 1}},
        main_product = "factory-3",
        localised_name = {"entity-name.factory-3"},
        categories = data.raw["recipe-category"]["metallurgy"] and {"metallurgy", "crafting"} or nil
    },
    -- Utilities
    {
        type = "recipe",
        name = "factory-circuit-connector",
        enabled = false,
        energy_required = 1,
        ingredients = {
            {type = "item", name = "electronic-circuit", amount = 2},
            {type = "item", name = "copper-cable",       amount = 5}
        },
        results = {{type = "item", name = "factory-circuit-connector", amount = 1}},
    }
}

if settings.startup["Factorissimo2-space-architecture"].value then
    data:extend {{
        type = "recipe",
        name = "space-factory-1",
        enabled = false,
        energy_required = 30,
        results = {{type = "item", name = "space-factory-1", amount = 1}},
        main_product = "space-factory-1",
        localised_name = {"entity-name.space-factory-1"},
    }}
    data:extend {{
        type = "recipe",
        name = "space-factory-2",
        enabled = false,
        energy_required = 45,
        results = {{type = "item", name = "space-factory-2", amount = 1}},
        main_product = "space-factory-2",
        localised_name = {"entity-name.space-factory-2"},
    }}
    data:extend {{
        type = "recipe",
        name = "space-factory-3",
        enabled = false,
        energy_required = 60,
        results = {{type = "item", name = "space-factory-3", amount = 1}},
        main_product = "space-factory-3",
        localised_name = {"entity-name.space-factory-3"},
    }}

    if mods["space-exploration"] then
        data.raw.recipe["space-factory-1"].ingredients = {
            {type = "item", name = "se-space-solar-panel",       amount = 10},
            {type = "item", name = "se-aeroframe-pole",          amount = 1000},
            {type = "item", name = "se-heat-shielding",          amount = 1000},
            {type = "item", name = "se-space-platform-scaffold", amount = 30 * 30},
            {type = "item", name = "substation",                 amount = 50},
        }
        data.raw.recipe["space-factory-2"].ingredients = {
            {type = "item", name = "se-space-solar-panel-2",    amount = 20},
            {type = "item", name = "se-aeroframe-scaffold",     amount = 1500},
            {type = "item", name = "se-heat-shielding",         amount = 1500},
            {type = "item", name = "se-space-platform-plating", amount = 46 * 46},
            {type = "item", name = "se-pylon",                  amount = 50},
        }
        data.raw.recipe["space-factory-3"].ingredients = {
            {type = "item", name = "se-space-solar-panel-3",             amount = 30},
            {type = "item", name = "se-aeroframe-bulkhead",              amount = 2000},
            {type = "item", name = "se-heavy-composite",                 amount = 2000},
            {type = "item", name = "se-spaceship-floor",                 amount = 60 * 60},
            {type = "item", name = "se-pylon-construction",              amount = 50},
            {type = "item", name = "se-deep-space-transport-belt-black", amount = 10},
        }
        data.raw.recipe["space-factory-1"].categories = {"space-manufacturing"}
        data.raw.recipe["space-factory-2"].categories = {"space-manufacturing"}
        data.raw.recipe["space-factory-3"].categories = {"space-manufacturing"}
    elseif mods["space-age"] and not mods["space-is-fake"] then
        data.raw.recipe["space-factory-1"].ingredients = {
            {type = "item", name = "factory-1",                 amount = 1},
            {type = "item", name = "low-density-structure",     amount = 500},
            {type = "item", name = "solar-panel",               amount = 10},
            {type = "item", name = "space-platform-foundation", amount = 300},
        }
        data.raw.recipe["space-factory-2"].ingredients = {
            {type = "item", name = "factory-2",                 amount = 1},
            {type = "item", name = "low-density-structure",     amount = 1000},
            {type = "item", name = "solar-panel",               amount = 30},
            {type = "item", name = "space-platform-foundation", amount = 600},
        }
        data.raw.recipe["space-factory-3"].ingredients = {
            {type = "item", name = "factory-3",                 amount = 1},
            {type = "item", name = "low-density-structure",     amount = 2000},
            {type = "item", name = "solar-panel",               amount = 50},
            {type = "item", name = "space-platform-foundation", amount = 900},
        }
        data.raw.recipe["space-factory-1"].categories = {"metallurgy"}
        data.raw.recipe["space-factory-2"].categories = {"metallurgy"}
        data.raw.recipe["space-factory-3"].categories = {"metallurgy"}
    end
end
