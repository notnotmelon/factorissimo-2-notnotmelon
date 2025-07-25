local F = "__factorissimo-2-notnotmelon__"
local pf = "p-q-"

local starting_planet = "nauvis"
if mods["any-planet-start"] then
    starting_planet = settings.startup["aps-planet"].value
    if starting_planet == "none" then starting_planet = "nauvis" end
end

local effects = {
    {
        type = "unlock-recipe",
        recipe = "factory-1"
    }
}

if not mods["solarsystemplusplus"] then
    effects[#effects + 1] = {
        type = "unlock-space-location",
        space_location = starting_planet .. "-factory-floor",
        use_icon_overlay_constant = false,
    }
end

data:extend {
    -- Factory buildings
    {
        type = "technology",
        name = "factory-architecture-t1",
        icon = F .. "/graphics/technology/factory-architecture-1.png",
        icon_size = 256,
        prerequisites = {"stone-wall", "logistics"},
        effects = effects,
        unit = {
            count = 200,
            ingredients = {{"automation-science-pack", 1}},
            time = 30
        },
        order = pf .. "a-a",
    },
    {
        type = "technology",
        name = "factory-architecture-t2",
        icon = F .. "/graphics/technology/factory-architecture-2.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t1", "steel-processing", "electric-energy-distribution-1"},
        effects = {
            {
                type = "unlock-recipe",
                recipe = "factory-2",
            }
        },
        unit = {
            count = 600,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}},
            time = 45
        },
        order = pf .. "a-b",
    },
    {
        type = "technology",
        name = "factory-architecture-t3",
        icon = F .. "/graphics/technology/factory-architecture-3.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t2", "concrete", "electric-energy-distribution-2", "production-science-pack"},
        effects = {
            {
                type = "unlock-recipe",
                recipe = "factory-3",
            }
        },
        unit = {
            count = 2000,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1}, {"production-science-pack", 1}},
            time = 60
        },
        order = pf .. "a-c",
    },

    -- Connection types
    {
        type = "technology",
        name = "factory-connection-type-fluid",
        icon = F .. "/graphics/technology/factory-connection-type-fluid.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t1"}, -- 'fluid-handling'
        effects = {},
        unit = {
            count = 100,
            ingredients = {{"automation-science-pack", 1}},
            time = 30
        },
        order = pf .. "c-a",
    },
    {
        type = "technology",
        name = "factory-connection-type-chest",
        icon = F .. "/graphics/technology/factory-connection-type-chest.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t2", "logistics-2"},
        effects = {},
        unit = {
            count = 200,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}},
            time = 30
        },
        order = pf .. "c-b",
    },
    {
        type = "technology",
        name = "factory-connection-type-circuit",
        icon = F .. "/graphics/technology/factory-connection-type-circuit.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t2", "circuit-network", "logistic-science-pack"},
        effects = {{type = "unlock-recipe", recipe = "factory-circuit-connector"}},
        unit = {
            count = 300,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}},
            time = 30
        },
        order = pf .. "c-c",
    },
    {
        type = "technology",
        name = "factory-connection-type-heat",
        icon = F .. "/graphics/technology/factory-connection-type-heat.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t2"},
        effects = {},
        unit = {
            count = 600,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}},
            time = 45
        },
        order = pf .. "c-d",
    },

    -- Utility upgrades

    {
        type = "technology",
        name = "factory-interior-upgrade-lights",
        icon = F .. "/graphics/technology/factory-interior-upgrade-lights.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t1", "lamp"},
        effects = {},
        unit = {
            count = 50,
            ingredients = {{"automation-science-pack", 1}},
            time = 30
        },
        order = pf .. "d-a",
    },
    {
        type = "technology",
        name = "factory-interior-upgrade-display",
        icon = F .. "/graphics/technology/factory-interior-upgrade-display.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t2", "lamp"},
        effects = {},
        unit = {
            count = 100,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}},
            time = 30
        },
        order = pf .. "d-b",
    },
    {
        type = "technology",
        name = "factory-preview",
        icon = F .. "/graphics/technology/factory-preview.png",
        icon_size = 256,
        prerequisites = {"factory-interior-upgrade-lights", "logistic-science-pack"},
        effects = {},
        unit = {
            count = 200,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}},
            time = 30
        },
        order = pf .. "d-c",
    },
    {
        type = "technology",
        name = "factory-interior-upgrade-roboport",
        icon = F .. "/graphics/technology/factory-interior-upgrade-roboport.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t2", "construction-robotics"},
        effects = {},
        unit = {
            count = 1000,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1}},
            time = 45
        },
        order = pf .. "d-d",
    },

    -- Recursion!

    {
        type = "technology",
        name = "factory-recursion-t1",
        icon = F .. "/graphics/technology/factory-recursion-1.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t2", "logistics-2"},
        effects = {},
        unit = {
            count = 2000,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}},
            time = 60
        },
        order = pf .. "b-a",
    },
    {
        type = "technology",
        name = "factory-recursion-t2",
        icon = F .. "/graphics/technology/factory-recursion-2.png",
        icon_size = 256,
        prerequisites = {"factory-recursion-t1", "factory-architecture-t3"},
        effects = {},
        unit = {
            count = 5000,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1}, {"production-science-pack", 1}},
            time = 60
        },
        order = pf .. "b-b",
    }
}
