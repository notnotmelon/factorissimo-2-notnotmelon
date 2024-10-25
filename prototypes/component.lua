local F = "__factorissimo-2-notnotmelon__";

require("circuit-connector-sprites")

local function cwc0c()
	return {shadow = {red = {0, 0}, green = {0, 0}, copper = {0, 0}}, wire = {red = {0, 0}, green = {0, 0}, copper = {0, 0}}}
end

local function blank()
	return {
		filename = F .. "/graphics/nothing.png",
		priority = "high",
		width = 1,
		height = 1,
	}
end

-- Factory power I/O

local function create_energy_interfaces(size, icon)
	local j = size / 2 - 0.3
	data:extend {{
		type = "electric-energy-interface",
		name = "factory-power-input-" .. size,
		icon = icon,
		icon_size = 64,
		flags = {"not-on-map"},
		minable = nil,
		max_health = 1,
		hidden = true,
		selectable_in_game = false,
		energy_source = {
			type = "electric",
			usage_priority = "tertiary",
			input_flow_limit = "0W",
			output_flow_limit = "0W",
			buffer_capacity = "0J",
			render_no_power_icon = false,
		},
		energy_usage = "0MW",
		energy_production = "0MW",
		selection_box = {{-j, -j}, {j, j}},
		collision_box = {{-j, -j}, {j, j}},
		collision_mask = {layers = {}},
		localised_name = "",
	}}
end

create_energy_interfaces(8, F .. "/graphics/icon/factory-1.png")
create_energy_interfaces(12, F .. "/graphics/icon/factory-2.png")
create_energy_interfaces(16, F .. "/graphics/icon/factory-3.png")

-- Connection indicators

data:extend {{
	type = "item",
	name = "factory-connection-indicator-settings",
	icon_size = 32,
	icon = F .. "/graphics/indicator/blueprint-settings.png",
	stack_size = 1,
	hidden = true,
	hidden_in_factoriopedia = true,
	flags = {"not-stackable", "only-in-cursor"}
}}

local function create_indicator(ctype, suffix, image)
	data:extend {{
		type                           = "storage-tank",
		name                           = "factory-connection-indicator-" .. ctype .. "-" .. suffix,
		localised_name                 = {"entity-name.factory-connection-indicator-" .. ctype},
		flags                          = {"not-on-map", "player-creation", "not-deconstructable"},
		placeable_by                   = {item = "factory-connection-indicator-settings", count = 1},
		max_health                     = 500,
		selection_box                  = {{-0.4, -0.4}, {0.4, 0.4}},
		collision_box                  = {{-0.4, -0.4}, {0.4, 0.4}},
		collision_mask                 = {not_colliding_with_itself = true, layers = {}},
		fluid_box                      = {
			volume = 1,
			pipe_connections = {},
		},
		hidden                         = true,
		two_direction_only             = false,
		window_bounding_box            = {{0, 0}, {0, 0}},
		pictures                       = {
			picture = {
				sheet = {
					filename = F .. "/graphics/indicator/" .. image .. ".png",
					priority = "extra-high",
					frames = 4,
					width = 32,
					height = 32
				},
			},
		},
		flow_length_in_ticks           = 100,
		circuit_wire_connection_points = table.deepcopy(circuit_connector_definitions["storage-tank"].points),
		circuit_connector_sprites      = table.deepcopy(circuit_connector_definitions["storage-tank"].sprites),
		circuit_wire_max_distance      = 0,
		se_allow_in_space              = true
	}}
end

create_indicator("belt", "d0", "green-dir")

create_indicator("chest", "d0", "brown-dir") -- 0 is catchall for "There isn't an entity for this exact value"
create_indicator("chest", "d10", "brown-dir")
create_indicator("chest", "d20", "brown-dir")
create_indicator("chest", "d60", "brown-dir")
create_indicator("chest", "d180", "brown-dir")
create_indicator("chest", "d600", "brown-dir")

create_indicator("chest", "b0", "brown-dot")
create_indicator("chest", "b10", "brown-dot")
create_indicator("chest", "b20", "brown-dot")
create_indicator("chest", "b60", "brown-dot")
create_indicator("chest", "b180", "brown-dot")
create_indicator("chest", "b600", "brown-dot")

create_indicator("fluid", "d0", "blue-dir")

create_indicator("heat", "b0", "yellow-dot")
create_indicator("heat", "b5", "yellow-dot")
create_indicator("heat", "b10", "yellow-dot")
create_indicator("heat", "b30", "yellow-dot")
create_indicator("heat", "b120", "yellow-dot")

create_indicator("circuit", "b0", "red-dot")

-- Other auxiliary entities

data:extend {{
	type = "simple-entity-with-force",
	name = "factory-blueprint-anchor",
	flags = {"player-creation", "placeable-off-grid"},
	hidden = true,
	collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
	selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
	placeable_by = {item = "simple-entity-with-force", count = 1}
}}

local j = 0.99
data:extend {{
	type = "electric-pole",
	name = "factory-power-pole",
	minable = nil,
	max_health = 1,
	selection_box = {{-j, -j}, {j, j}},
	collision_box = {{-j, -j}, {j, j}},
	collision_mask = {layers = {}},
	flags = {"not-on-map"},
	auto_connect_up_to_n_wires = 0,
	hidden = true,
	maximum_wire_distance = 1,
	supply_area_distance = 63,
	pictures = table.deepcopy(data.raw["electric-pole"]["substation"].pictures),
	drawing_box = table.deepcopy(data.raw["electric-pole"]["substation"].drawing_box),
	radius_visualisation_picture = blank(),
	connection_points = {cwc0c(), cwc0c(), cwc0c(), cwc0c()},
}}

data:extend {{
	type = "item",
	name = "factory-overlay-controller-settings",
	icon_size = data.raw.item["display-panel"].icon_size,
	icon = data.raw.item["display-panel"].icon,
	icon_mipmaps = data.raw.item["display-panel"].icon_mipmaps,
	stack_size = 1,
	hidden = true,
	hidden_in_factoriopedia = true,
	flags = {"not-stackable", "only-in-cursor"},
	place_result = "factory-overlay-controller"
}}

local overlay_controller = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
overlay_controller.sprites = table.deepcopy(data.raw["display-panel"]["display-panel"].sprites)
overlay_controller.name = "factory-overlay-controller"
overlay_controller.circuit_wire_max_distance = 0
overlay_controller.collision_mask = {layers = {}}
data:extend {overlay_controller}

data:extend {
	{
		type = "radar",
		name = "factory-hidden-radar",
		selectable_in_game = false,
		flags = {"not-on-map", "hide-alt-info"},
		hidden = true,
		collision_mask = {layers = {}},
		energy_per_nearby_scan = "0W",
		energy_per_sector = "1W",
		energy_source = {type = "void"},
		energy_usage = "1W",
		max_distance_of_sector_revealed = 0,
		max_distance_of_nearby_sector_revealed = 1,
		localised_name = "",
		max_health = 1
	},
	{
		type = "heat-pipe",
		name = "factory-heat-dummy-connector",
		selectable_in_game = false,
		flags = {"not-on-map", "hide-alt-info"},
		hidden = true,
		collision_mask = {layers = {}},
		collision_box = table.deepcopy(data.raw["heat-pipe"]["heat-pipe"].collision_box),
		localised_name = {"entity-name.heat-pipe"},
		max_health = 1,
		heat_buffer = {
			max_temperature = 0,
			specific_heat = "1W",
			max_transfer = "1W",
			default_temperature = 0,
			min_working_temperature = 0,
			min_temperature_gradient = 0,
			connections = table.deepcopy(data.raw["heat-pipe"]["heat-pipe"].heat_buffer.connections)
		}
	}
}
