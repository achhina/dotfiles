return {
	-- Dropbar.nvim - VS Code-style winbar with robust terminal resizing
	{
		"Bekaboo/dropbar.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("dropbar").setup({
				general = {
					update_debounce = 100, -- Smooth scrolling, prevents rapid updates
				},
				bar = {
					truncate = true, -- Automatically truncate long paths
				},
				menu = {
					preview = true, -- Enable hover previews
				},
			})
		end,
	},
}
