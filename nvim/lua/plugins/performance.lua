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

}
