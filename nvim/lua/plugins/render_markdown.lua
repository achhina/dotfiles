return {
	"MeanderingProgrammer/render-markdown.nvim",
	opts = {
		-- Disable LaTeX support to avoid detex dependency
		latex = {
			enabled = false,
		},
	},
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-mini/mini.nvim",
	},
}
