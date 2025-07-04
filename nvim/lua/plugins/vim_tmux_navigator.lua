return {
	"christoomey/vim-tmux-navigator",
	lazy = false, -- Load immediately since keymaps are essential
	config = function()
		vim.g.tmux_navigator_disable_when_zoomed = 1

		-- Set up keymaps manually to ensure they work
		vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Navigate Left", silent = true })
		vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Navigate Down", silent = true })
		vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Navigate Up", silent = true })
		vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Navigate Right", silent = true })
		vim.keymap.set("n", "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", { desc = "Navigate Previous", silent = true })
	end,
}
