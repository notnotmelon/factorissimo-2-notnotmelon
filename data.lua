require "prototypes.factory"
require "prototypes.component"
require "prototypes.utility"
require "prototypes.recipe"
require "prototypes.technology"
require "prototypes.tile"
require "prototypes.borehole-pump"
require "prototypes.roboport"
require "prototypes.space-age-rebalance"

data:extend {
	{
		type = "item-subgroup",
		name = "factorissimo2",
		group = "logistics",
		order = "e-e"
	},
	{
		type = "custom-input",
		name = "factory-rotate",
		key_sequence = "R",
	},
	{
		type = "custom-input",
		name = "factory-increase",
		key_sequence = "SHIFT + R",
	},
	{
		type = "custom-input",
		name = "factory-decrease",
		key_sequence = "CONTROL + R",
	},
}

if mods["power-grid-comb"] then
	require "compat.powergridcomb"
end
