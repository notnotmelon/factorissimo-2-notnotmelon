require "__factorissimo-2-notnotmelon__.script.electricity"

for _, pole in ipairs(storage.middleman_power_poles) do
    if pole ~= 0 then pole.destroy() end
end

for _, factory in pairs(storage.factories) do
    for _, inside_power_pole in pairs(factory.inside_power_poles or {}) do
        if inside_power_pole and inside_power_pole.valid then
            inside_power_pole.destroy()
        end
    end
    factory.inside_power_poles = nil
    factory.middleman_id = nil
    factory.direct_connection = nil

    Electricity.update_power_connection(factory)
end

local new_surface_factories = {}
for surface_name, factory_list in pairs(storage.surface_factories or {}) do
    if type(surface_name) == "string" then
        local surface = game.get_surface(surface_name)
        new_surface_factories[surface.index] = factory_list
    else
        new_surface_factories[surface_name] = factory_list
    end
end

storage.surface_factory_counters = nil

local old_factory_surface = game.surfaces["factory-floor-1"]
local planet = game.planets["nauvis-factory-floor"]
if old_factory_surface and planet and not planet.surface then
    planet.associate_surface(old_factory_surface)
end