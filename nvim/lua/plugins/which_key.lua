return {
	"folke/which-key.nvim",
	dependencies = { "nvim-mini/mini.icons" },
	event = "VeryLazy",
	opts = {
		spec = {
			{ "<leader>a", group = "AI/Claude Code" },
			{ "<leader>sw", group = "Swap" },
			{ "<leader>t", group = "Test" },
			{ "<leader>g", group = "Git" },
			{ "<leader>gh", group = "Git Hunks" },
			{ "<leader>gt", group = "Git Toggle" },
			{ "<leader>o", group = "Options" },
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
