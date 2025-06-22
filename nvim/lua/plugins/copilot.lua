return {
	-- Copilot-style inline suggestions
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				panel = {
					enabled = false, -- We'll use inline suggestions
					auto_refresh = true,
				},
				suggestion = {
					enabled = true,
					auto_trigger = true,
					debounce = 75,
					keymap = {
						accept = "<M-l>", -- Alt+l to accept
						accept_word = "<M-w>", -- Alt+w to accept word
						accept_line = "<M-j>", -- Alt+j to accept line
						next = "<M-]>", -- Alt+] for next suggestion
						prev = "<M-[>", -- Alt+[ for prev suggestion
						dismiss = "<C-]>", -- Ctrl+] to dismiss
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
