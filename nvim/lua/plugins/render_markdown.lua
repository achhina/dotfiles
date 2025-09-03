return {
	"MeanderingProgrammer/render-markdown.nvim",
	opts = {
		-- Use detex instead of latex2text for LaTeX processing
		latex = {
			converter = "detex",
		},
	},
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-mini/mini.nvim",
	},
}
