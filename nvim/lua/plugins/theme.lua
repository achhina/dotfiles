local themes = {
	rose_pine = {
		"rose-pine/neovim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("rose-pine")
		end,
	},

	night_owl = {
		"oxfist/night-owl.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("night-owl")
		end,
	},
}

return themes.night_owl
