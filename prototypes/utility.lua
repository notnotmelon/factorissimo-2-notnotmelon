local F = "__factorissimo-2-notnotmelon__"

-- Circuit connectors

data:extend {{
	type = "item",
	name = "factory-circuit-connector",
	icon = F .. "/graphics/icon/factory-circuit-connector.png",
	icon_size = 64,
	flags = {},
	subgroup = "factorissimo2",
	order = "c-b",
	place_result = "factory-circuit-connector",
	stack_size = 50,
}}

data:extend {{
	type = "electric-pole",
	name = "factory-circuit-connector",
	icon = F .. "/graphics/icon/factory-circuit-connector.png",
	icon_size = 64,
	flags = {"placeable-neutral", "player-creation"},
	minable = {hardness = 0.2, mining_time = 0.5, result = "factory-circuit-connector"},
	max_health = 50,
	corpse = "small-remnants",
	supply_area_distance = 0,
	draw_copper_wires = false,
	collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
	selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
	item_slot_count = 15,
	pictures = {
		direction_count = 1,
		filename = F .. "/graphics/utility/factory-combinators.png",
		width = 79,
		height = 63,
		frame_count = 1,
		shift = {0.140625, 0.140625},
	},
	connection_points = {{
		shadow = {
			red = {0.75, 0.5625},
			green = {0.21875, 0.5625}
		},
		wire = {
			red = {0.28125, 0.15625},
			green = {-0.21875, 0.15625}
		}
	}},
	maximum_wire_distance = 7.5
}}

-- Heat source to make aquilo work

data:extend {{
	type = "heat-interface",
	name = "factory-heat-source",
	localised_name = {"entity-name.factory-heat-source"},
	localised_description = {"entity-description.factory-heat-source"},
	icon = F .. "/graphics/icon/factory-circuit-connector.png",
	icon_size = 64,
	flags = {"not-blueprintable", "not-deconstructable", "not-on-map", "not-flammable", "not-repairable"},
	max_health = 50,
	corpse = "small-remnants",
	hidden = true,
	heat_buffer = {
		max_temperature = 1000,
		default_temperature = 1000,
		min_working_temperature = 1000,
		specific_heat = "1MJ",
		max_transfer = "1GW",
	},
}}
