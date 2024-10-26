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
	minable = {mining_time = 0.5, result = "factory-circuit-connector"},
	max_health = 50,
	corpse = "small-remnants",
	supply_area_distance = 0,
	draw_copper_wires = false,
	collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
	selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
	auto_connect_up_to_n_wires = 0,
	pictures = {
		direction_count = 1,
		filename = F .. "/graphics/utility/factory-combinators.png",
		width = 79,
		height = 63,
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
	maximum_wire_distance = 14,
}}

local factory_circuit_connector_invisible = table.deepcopy(data.raw["electric-pole"]["factory-circuit-connector"])
factory_circuit_connector_invisible.name = "factory-circuit-connector-invisible"
factory_circuit_connector_invisible.localised_name = {"entity-name.factory-circuit-connector"}
factory_circuit_connector_invisible.localised_description = {"entity-description.factory-circuit-connector"}
factory_circuit_connector_invisible.pictures = nil
factory_circuit_connector_invisible.selection_box = nil
factory_circuit_connector_invisible.minable = nil
factory_circuit_connector_invisible.corpse = nil
factory_circuit_connector_invisible.hidden = true
factory_circuit_connector_invisible.draw_circuit_wires = false
factory_circuit_connector_invisible.draw_copper_wires = false
factory_circuit_connector_invisible.factoriopedia_alternative = "factory-circuit-connector"
data:extend {factory_circuit_connector_invisible}

-- Heat source to make aquilo work

if feature_flags.space_travel then
	data:extend {{
		type = "heat-pipe",
		name = "factory-heat-source",
		localised_name = "",
		icon = F .. "/graphics/icon/factory-circuit-connector.png",
		icon_size = 64,
		flags = {"not-blueprintable", "not-deconstructable", "not-on-map", "not-flammable", "not-repairable"},
		max_health = 50,
		corpse = "small-remnants",
		hidden = true,
		heat_buffer = {
			max_temperature = 1000000,
			default_temperature = 15,
			min_working_temperature = 15,
			specific_heat = "1QJ", -- I don't want to mess with heat interface nonsense. This should last forever.
			max_transfer = "1QW",
			connections = table.deepcopy(data.raw["heat-pipe"]["heat-pipe"].heat_buffer.connections),
		},
		collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
		collision_mask = {layers = {}},
	}}
end
