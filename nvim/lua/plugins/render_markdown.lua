return {
	"MeanderingProgrammer/render-markdown.nvim",
	opts = {
		-- Disable LaTeX support since latex2text is not available
		latex = { enabled = false },
	},
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"echasnovski/mini.nvim",
	},
}
