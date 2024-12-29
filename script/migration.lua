-- Fix common migration issues.

factorissimo.on_event(factorissimo.events.on_init(), function()
    for _, factory in pairs(storage.factories) do
        -- Fix issues when forces are deleted.
        if not factory.force or not factory.force.valid then
            factory.force = game.forces.player
        end
        -- Fix issues when quality prototypes are removed.
        if not factory.quality or not factory.quality.valid then
            if factory.building and factory.building.valid then
                factory.quality = factory.building.quality
            else
                factory.quality = prototypes.quality.normal
            end
        end
        -- Ensure that original planet is set.
        if not factory.original_planet and factory.outside_surface and factory.outside_surface.valid then
            factory.original_planet = factory.outside_surface.planet
        end
    end
end)