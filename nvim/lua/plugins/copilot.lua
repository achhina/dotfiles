return {
	-- Copilot-style inline suggestions
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				panel = {
					enabled = false, -- Disabled - using copilot-cmp instead
					auto_refresh = true,
				},
				suggestion = {
					enabled = false, -- Disabled - using copilot-cmp instead
					auto_trigger = false,
					debounce = 75,
					keymap = {
						accept = false, -- Disabled - using copilot-cmp
						accept_word = false,
						accept_line = false,
						next = false,
						prev = false,
						dismiss = false,
					},
				},
				filetypes = {
					yaml = false,
					markdown = false,
					help = false,
					gitcommit = false,
					gitrebase = false,
					hgcommit = false,
					svn = false,
					cvs = false,
					["."] = false,
				},
				copilot_node_command = "node", -- Node.js version must be > 16.x
				server_opts_overrides = {},
			})
		end,
	},

	-- Enhanced completion with Copilot integration
	{
		"zbirenbaum/copilot-cmp",
		dependencies = "copilot.lua",
		opts = {},
		config = function(_, opts)
			require("copilot_cmp").setup(opts)
		end,
	},
}
