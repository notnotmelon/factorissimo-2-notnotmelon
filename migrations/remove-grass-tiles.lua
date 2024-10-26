for _, surface in pairs(game.surfaces) do
    if surface.name:find("%-factory%-floor$") then
        surface.freeze_daytime = true
        surface.daytime = 0.5
        if remote.interfaces["RSO"] then
            pcall(remote.call, "RSO", "ignoreSurface", surface.name)
        end
        local mgs = surface.map_gen_settings
        mgs.width = 2
        mgs.height = 2
        surface.map_gen_settings = mgs

        local grass_1 = surface.find_tiles_filtered {name = "grass-1"}
        local new_tiles = {}
        for _, tile in pairs(grass_1) do
            table.insert(new_tiles, {name = "out-of-map", position = tile.position})
        end
        surface.set_tiles(new_tiles)

        for _, force in pairs(game.forces) do
            if force.technologies["factory-interior-upgrade-lights"].researched then
                surface.daytime = 1
                break
            end
        end
    end
end