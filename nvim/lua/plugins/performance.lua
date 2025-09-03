return {
	-- Startup time analysis
	{
		"dstein64/vim-startuptime",
		cmd = "StartupTime",
		config = function()
			vim.g.startuptime_tries = 10
		end,
	},

	-- Better buffer management and memory optimization
	{
		"nvim-mini/mini.bufremove",
		event = "VeryLazy",
		keys = {
			{
				"<leader>bd",
				function()
					require("mini.bufremove").delete(0, false)
				end,
				desc = "Delete buffer",
			},
			{
				"<leader>bD",
				function()
					require("mini.bufremove").delete(0, true)
				end,
				desc = "Delete buffer (force)",
			},
		},
		config = function()
			require("mini.bufremove").setup()
		end,
	},

	-- Performance optimization for large files
	{
		"LunarVim/bigfile.nvim",
		event = "BufReadPre",
		config = function()
			require("bigfile").setup({
				filesize = 2, -- size of the file in MiB, the plugin round file sizes to the closest MiB
				pattern = { "*" }, -- autocmd pattern or function see <nvim_create_autocmd>
				features = { -- features to disable
					"indent_blankline",
					"illuminate",
					"lsp",
					"treesitter",
					"syntax",
					"matchparen",
					"vimopts",
					"filetype",
				},
			})
		end,
	},
}
