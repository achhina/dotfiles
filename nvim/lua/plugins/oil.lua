return {
	"stevearc/oil.nvim",
	---@module 'oil'
	---@type oil.SetupOpts
	-- Optional dependencies
	dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
	-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
	lazy = false,
	config = function()
		vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
		-- Disable keymaps related to vim/tmux navigation
		local oil = require("oil")
		oil.setup({
			keymaps = {
				["<C-h>"] = false,
				["<C-l>"] = false,
			},
		})
	end,
}
