Lights = {}

function Lights.build_lights_upgrade(factory)
    if not factory.inside_surface.valid then return end
    local force = factory.force
    if not force.valid then return end
    local has_tech = force.technologies["factory-interior-upgrade-lights"].researched

    factory.inside_surface.daytime = has_tech and 1 or 0.5
end
