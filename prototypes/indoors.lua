if not feature_flags.space_travel then return end

local banned_from_being_placed_indoors = {
    "artillery-turret",
    "rocket-silo",
    "cargo-landing-pad",
    --"solar-panel"
}

for _, prototype in pairs(banned_from_being_placed_indoors) do
    for _, entity in pairs(data.raw[prototype]) do
        entity.surface_conditions = entity.surface_conditions or {}
        table.insert(entity.surface_conditions, {
            property = "indoors",
            max = 0,
        })
    end
end

data:extend{{
    name = "indoors",
    type = "surface-property",
    default_value = 0,
    is_time = true
}}