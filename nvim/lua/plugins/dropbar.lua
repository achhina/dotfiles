return {
	-- Dropbar.nvim - VS Code-style winbar with robust terminal resizing
	{
		"Bekaboo/dropbar.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("dropbar").setup({
				bar = {
					truncate = true, -- Automatically truncate long paths
					update_debounce = 100, -- Smooth scrolling, prevents rapid updates (moved from general)
				},
				menu = {
					preview = true, -- Enable hover previews
				},
			})
		end,
	},
}
