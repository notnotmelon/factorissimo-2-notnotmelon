for _, factory in pairs(storage.factories or {}) do
    if factory.radar.valid then
        factory.radar.disabled_by_script = true
    end
end
storage.hidden_radars = nil
