if mods["space-age"] then
    data:extend {{
        type = "bool-setting",
        name = "Factorissimo2-cheap-research",
        setting_type = "startup",
        default_value = false,
        order = "a-c",
    }}
end

data:extend {
    -- Startup
    {
        type = "bool-setting",
        name = "Factorissimo2-disable-new-tile-effects",
        setting_type = "startup",
        default_value = false,
        order = "a-b",
    },
    -- Global
    {
        type = "bool-setting",
        name = "Factorissimo2-free-recursion",
        setting_type = "runtime-global",
        default_value = false,
        order = "a-a",
    },
    {
        type = "bool-setting",
        name = "Factorissimo2-hide-recursion",
        setting_type = "runtime-global",
        default_value = false,
        order = "a-b",
    },
    {
        type = "bool-setting",
        name = "Factorissimo2-hide-recursion-2",
        setting_type = "runtime-global",
        default_value = false,
        order = "a-b-a",
    },
    {
        type = "bool-setting",
        name = "Factorissimo2-better-recursion-2",
        setting_type = "runtime-global",
        default_value = true,
        order = "a-c",
    },
    {
        type = "bool-setting",
        name = "Factorissimo2-indestructible-buildings",
        setting_type = "runtime-global",
        default_value = false,
        order = "a-e",
    },
    {
        type = "string-setting",
        name = "Factorissimo2-factory-preview-mode",
        setting_type = "runtime-per-user",
        default_value = "fancy",
        allowed_values = {"fancy", "subtle", "off"},
        order = "a-c",
    },
}
