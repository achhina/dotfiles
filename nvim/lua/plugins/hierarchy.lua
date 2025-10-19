return {
	"Slyces/hierarchy.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	keys = {
		{
			"gp",
			function()
				require("hierarchy").supertypes(require("hierarchy.handlers").jump_first)
			end,
			desc = "Go to parent class/method",
		},
		{
			"<leader>lp",
			function()
				require("hierarchy").supertypes(require("hierarchy.handlers").telescope)
			end,
			desc = "LSP: Parent class hierarchy (telescope)",
		},
		{
			"<leader>lc",
			function()
				require("hierarchy").subtypes(require("hierarchy.handlers").telescope)
			end,
			desc = "LSP: Child class hierarchy (telescope)",
		},
	},
	config = function()
		require("hierarchy").setup({
			handlers = {
				telescope = require("hierarchy.handlers").telescope,
			},
		})
	end,
}
