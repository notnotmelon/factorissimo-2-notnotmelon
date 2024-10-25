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
	maximum_wire_distance = 7.5
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

-- Hidden pumps to work around the extents @raiguard

local pump_pictures = {
	north = data.raw.pipe.pipe.pictures.ending_up,
	south = data.raw.pipe.pipe.pictures.ending_down,
	east = data.raw.pipe.pipe.pictures.ending_right,
	west = data.raw.pipe.pipe.pictures.ending_left,
}

data:extend {{
	type = "pump",
	name = "factory-inside-pump-input",
	icon = data.raw["pump"]["pump"].icon,
	icon_size = data.raw["pump"]["pump"].icon_size,
	localised_name = "",
	flags = {"not-blueprintable", "not-deconstructable", "not-on-map", "not-flammable", "not-repairable", "hide-alt-info"},
	max_health = 50,
	corpse = "small-remnants",
	hidden = true,
	fluid_box = {
		volume = 500,
		hide_connection_info = true,
		pipe_connections = {
			{position = {0, 0}, direction = defines.direction.north, flow_direction = "input",  connection_type = "normal"},
			{position = {0, 0}, direction = defines.direction.south, flow_direction = "output", connection_type = "linked", linked_connection_id = 0},
		},
	},
	energy_source = {
		type = "void",
	},
	integration_patch = table.deepcopy(pump_pictures),
	integration_patch_render_layer = "lower-object-above-shadow",
	pumping_speed = data.raw["pump"]["pump"].pumping_speed * 10,
	energy_usage = "1W",
	collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
	quality_indicator_scale = 0,
}}

data:extend {{
	type = "pump",
	name = "factory-inside-pump-output",
	icon = data.raw["pump"]["pump"].icon,
	icon_size = data.raw["pump"]["pump"].icon_size,
	localised_name = "",
	flags = {"not-blueprintable", "not-deconstructable", "not-on-map", "not-flammable", "not-repairable", "hide-alt-info"},
	max_health = 50,
	corpse = "small-remnants",
	hidden = true,
	fluid_box = {
		volume = 500,
		hide_connection_info = true,
		pipe_connections = {
			{position = {0, 0}, direction = defines.direction.north, flow_direction = "output", connection_type = "normal"},
			{position = {0, 0}, direction = defines.direction.south, flow_direction = "input",  connection_type = "linked", linked_connection_id = 0},
		},
	},
	integration_patch = table.deepcopy(pump_pictures),
	integration_patch_render_layer = "lower-object-above-shadow",
	energy_source = {
		type = "void",
	},
	pumping_speed = data.raw["pump"]["pump"].pumping_speed * 10,
	energy_usage = "1W",
	collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
	quality_indicator_scale = 0,
}}

local outside_input = table.deepcopy(data.raw["pump"]["factory-inside-pump-input"])
outside_input.name = "factory-outside-pump-input"
outside_input.animations = nil

local outside_output = table.deepcopy(data.raw["pump"]["factory-inside-pump-output"])
outside_output.name = "factory-outside-pump-output"
outside_output.animations = nil

data:extend {outside_input, outside_output}
