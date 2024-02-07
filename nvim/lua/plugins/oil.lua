return {
	"stevearc/oil.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = { view_options = { show_hidden = true } },
	keys = { { "-", mode = "n", "<CMD>Oil<CR>", desc = "Open parent directory" } },
}
