return {
	-- Breadcrumbs/context in winbar
	{
		"SmiteshP/nvim-navic",
		lazy = true,
		init = function()
			vim.g.navic_silence = true
		end,
		opts = {
			separator = " > ",
			highlight = true,
			depth_limit = 5,
			depth_limit_indicator = "..",
			safe_output = true,
			lazy_update_context = false,
			click = true,
			format_text = function(text)
				return text
			end,
		},
		config = function(_, opts)
			require("nvim-navic").setup(opts)

			-- Setup winbar to show breadcrumbs
			vim.api.nvim_create_autocmd({ "CursorMoved", "BufWinEnter", "BufFilePost" }, {
				callback = function()
					local navic = require("nvim-navic")
					if navic.is_available() then
						vim.opt_local.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
					else
						vim.opt_local.winbar = "%f" -- Fallback to filename
					end
				end,
			})
		end,
	},

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
