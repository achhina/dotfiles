return {
	{
		dir = vim.fn.stdpath("config") .. "/lua/nvim-debug",
		name = "nvim-debug",
		lazy = false,
		config = function()
			require("nvim-debug").setup()
		end,
	},
}
