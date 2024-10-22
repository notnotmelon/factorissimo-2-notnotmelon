require "__factorissimo-2-notnotmelon__.script.electricty"

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

    Electricity.update_power_connection(factory)
end