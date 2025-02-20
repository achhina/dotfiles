-- luacheck: globals Snacks
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
		image = {
			enabled = true,
		},
	},
	keys = {
		-- zen
		{
			"<leader>z",
			function()
				Snacks.zen()
			end,
			desc = "Toggle Zen Mode",
		},
		{
			"<leader>Z",
			function()
				Snacks.zen.zoom()
			end,
			desc = "Toggle Zoom",
		},
	},
	config = function(_, opts)
		opts.dashboard = {
			preset = {
				header = table.concat(require("ascii.art").misc.krakens.sleekraken, "\n"),
			},
		}
		vim.api.nvim_create_user_command("Dashboard", Snacks.dashboard.open, {})
		Snacks.setup(opts)
	end,
}
