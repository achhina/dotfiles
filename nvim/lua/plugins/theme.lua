local themes = {
	rose_pine = {
		"rose-pine/neovim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("rose-pine-main")
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

	tokyo_dark = {
		"tiagovla/tokyodark.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("tokyodark")
		end,
	},
}

return themes.tokyo_dark
