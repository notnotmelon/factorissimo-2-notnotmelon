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

local linked_belts = {}
for _, type in ipairs {"linked-belt", "transport-belt", "underground-belt", "loader-1x1", "loader", "splitter", "lane-splitter"} do
	for _, belt in pairs(data.raw[type]) do
		if belt.collision_mask and belt.collision_mask.layers and not belt.collision_mask.layers.transport_belt then
			belt.collision_mask.layers.transport_belt = true -- Fixes a crash with advanced furances 2
		end

		local linked = table.deepcopy(belt)
		linked.allow_side_loading = false
		linked.type = "linked-belt"
		linked.next_upgrade = nil
		if not linked.localised_name then linked.localised_name = {"entity-name." .. linked.name} end
		linked.name = "factory-linked-" .. linked.name
		linked.structure = {
			direction_in = blank(),
			direction_out = blank()
		}
		linked.heating_energy = nil
		linked.selection_box = nil
		linked.minable = nil
		linked.hidden = true
		linked.belt_length = nil
		linked.collision_mask = {layers = {transport_belt = true}}
		linked.filter_count = nil
		linked.structure_render_layer = nil
		linked.container_distance = nil
		linked.belt_length = nil
		if type == "loader" or type == "splitter" then linked.collision_box = {{-0.4, -0.4}, {0.4, 0.4}} end

		linked_belts[#linked_belts + 1] = linked
	end
end
data:extend(linked_belts)

if data.raw["assembling-machine"]["borehole-pump"] then
	local borehole_fluids = {}
	for _, tile in pairs(data.raw.tile) do
		if tile.autoplace and tile.fluid and not tile.hidden and not borehole_fluids[tile.fluid] then
			borehole_fluids[tile.fluid] = true
			local fluid = data.raw.fluid[tile.fluid]
			local recipe_name = "borehole-pump-" .. tile.fluid
			data:extend{{
				type = "recipe",
				name = recipe_name,
				localised_name = fluid.localised_name or {"fluid-name." .. fluid.name},
				enabled = false,
				ingredients = {},
				energy_required = 4,
				allow_productivity = true,
				category = "borehole-pump",
				results = {
					{type = "fluid", name = tile.fluid, amount = 600}
				},
				surface_conditions = table.deepcopy(data.raw["assembling-machine"]["borehole-pump"].surface_conditions)
			}}
			table.insert(data.raw.technology["factory-upgrade-borehole-pump"].effects, {type = "unlock-recipe", recipe = recipe_name})
		end
	end

	local function add_surface_conditions_to_borehole_recipe(recipe_name, conditions_source_to_copy)
		local recipe = data.raw.recipe[recipe_name]
		if not recipe then return end
		if not conditions_source_to_copy then return end

		recipe.surface_conditions = recipe.surface_conditions or {}
		for _, condition in pairs(table.deepcopy(conditions_source_to_copy.surface_conditions)) do
			table.insert(recipe.surface_conditions, condition)
		end
	end
	
	add_surface_conditions_to_borehole_recipe("borehole-pump-heavy-oil", data.raw.recipe["electromagnetic-science-pack"])
	add_surface_conditions_to_borehole_recipe("borehole-pump-ammoniacal-solution", data.raw.recipe["cryogenic-science-pack"])
	add_surface_conditions_to_borehole_recipe("borehole-pump-lava", data.raw.recipe["metallurgic-science-pack"])
	add_surface_conditions_to_borehole_recipe("borehole-pump-water", (data.raw["agricultural-tower"] or {})["agricultural-tower"])
end