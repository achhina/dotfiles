return {
	"folke/which-key.nvim",
	dependencies = { "echasnovski/mini.icons" },
	event = "VeryLazy",
	opts = {
		spec = {
			{ "<leader>sw", group = "Swap" },
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},
}
