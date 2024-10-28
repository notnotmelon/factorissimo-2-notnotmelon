remote_api = remote_api or {}

require "__factorissimo-2-notnotmelon__.script.layout"
Layout.init()

for _, factory in pairs(storage.factories) do
    local quality = factory.quality
    if not quality or not quality.valid then
        if factory.building and factory.building.valid then
            quality = factory.building.quality
        else
            quality = prototypes.quality.normal
        end
    end

    factory.layout = Layout.create_layout(factory.layout.name, factory.quality)
    if not factory.inside_overlay_controller or not factory.inside_overlay_controller.valid then goto continue end
    local overlay = factory.inside_overlay_controller
    overlay.teleport{
        x = factory.layout.overlays.inside_x + factory.inside_x,
        y = factory.layout.overlays.inside_y + factory.inside_y,
    }
    ::continue::
end
