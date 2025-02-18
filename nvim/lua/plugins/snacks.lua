return {
	"folke/snacks.nvim",
	dependencies = {
		-- Used for dashboard ascii art
		"MaximilianLloyd/ascii.nvim",
	},
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		bigfile = { enabled = false },
		dashboard = {
			enabled = true,
		},
		explorer = { enabled = false },
		indent = { enabled = false },
		input = { enabled = false },
		picker = { enabled = false },
		notifier = { enabled = false },
		quickfile = { enabled = false },
		scope = { enabled = false },
		scroll = { enabled = false },
		statuscolumn = { enabled = false },
		words = { enabled = false },
	},
	config = function()
		local opts = {
			dashboard = {
				preset = {
					header = table.concat(require("ascii.art").misc.krakens.sleekraken, "\n"),
				},
			},
		}
		require("snacks").setup(opts)
	end,
}
