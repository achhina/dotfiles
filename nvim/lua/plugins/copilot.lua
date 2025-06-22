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
				server_opts_overrides = {
					-- Explicitly prevent LSP server registration
					name = "copilot_agent", -- Use a different name to avoid conflicts
				},
			})
		end,
	},

	-- Enhanced completion with Copilot integration
	{
		"zbirenbaum/copilot-cmp",
		dependencies = "copilot.lua",
		opts = {},
		config = function(_, opts)
			-- Ensure copilot.lua is loaded first and disable LSP registration
			local copilot_ok, _ = pcall(require, "copilot")
			if not copilot_ok then
				vim.notify("Copilot.lua not available, skipping copilot-cmp setup", vim.log.levels.WARN)
				return
			end

			-- Setup copilot-cmp with safe error handling
			local copilot_cmp_ok, copilot_cmp = pcall(require, "copilot_cmp")
			if copilot_cmp_ok then
				copilot_cmp.setup(vim.tbl_extend("force", {
					-- Ensure it doesn't register as LSP server
					method = "getCompletionsCycling", -- Use the completion method, not LSP
				}, opts))
			else
				vim.notify("Failed to setup copilot-cmp", vim.log.levels.ERROR)
			end
		end,
	},
}
