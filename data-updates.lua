require "prototypes.space-location"
require "prototypes.ceiling"
require "prototypes.factory-pumps"
require "prototypes.quality-tooltips"

local F = "__factorissimo-2-notnotmelon__"

local function blank()
	return {
		filename = F .. "/graphics/nothing.png",
		priority = "high",
		width = 1,
		height = 1
	}
end

for _, type in ipairs {"linked-belt", "transport-belt", "underground-belt", "loader-1x1", "loader", "splitter", "lane-splitter"} do
	for _, belt in pairs(table.deepcopy(data.raw[type])) do
		local linked = belt
		linked.allow_side_loading = false
		linked.type = "linked-belt"
		linked.next_upgrade = nil
		if not linked.localised_name then linked.localised_name = {"entity-name." .. linked.name} end
		linked.name = "factory-linked-" .. linked.name
		linked.structure = {
			direction_in = blank(),
			direction_out = blank()
		}
		linked.selection_box = nil
		linked.minable = nil
		linked.hidden = true
		linked.belt_length = nil
		linked.filter_count = nil
		linked.structure_render_layer = nil
		linked.container_distance = nil
		linked.belt_length = nil
		if type == "loader" or type == "splitter" then linked.collision_box = {{-0.4, -0.4}, {0.4, 0.4}} end

		data:extend {linked}
	end
end
