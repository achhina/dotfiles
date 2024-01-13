return {
	"folke/zen-mode.nvim",
	config = function()
		vim.keymap.set("n", "<C-w>o", require("zen-mode").toggle, { silent = true, desc = "Toggle Zen Mode" })
	end,
}
