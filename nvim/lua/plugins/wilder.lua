return {
	-- Enhanced command-line completion with auto-popup
	{
		"gelguy/wilder.nvim",
		event = "CmdlineEnter",
		config = function()
			local wilder = require("wilder")
			wilder.setup({ modes = { ":", "/", "?" } })

			-- Enable fuzzy matching
			wilder.set_option(
				"pipeline",
				wilder.branch(
					wilder.cmdline_pipeline({
						fuzzy = 1,
						fuzzy_filter = wilder.lua_fzy_filter(),
					}),
					wilder.vim_search_pipeline()
				)
			)

			-- Set up the popup menu
			wilder.set_option(
				"renderer",
				wilder.popupmenu_renderer(wilder.popupmenu_border_theme({
					highlights = {
						border = "Normal", -- highlight to use for the border
					},
					-- 'single', 'double', 'rounded' or 'solid'
					-- can also be a list of 8 characters, see :h wilder#popupmenu_border_theme() for more details
					border = "rounded",
					max_height = "75%", -- max height of the palette
					min_height = 0, -- set to the same as 'max_height' for a fixed height window
					prompt_position = "top", -- 'top' or 'bottom' to set the location of the prompt
					reverse = 0, -- set to 1 to reverse the order of the list, use in combination with 'prompt_position'
				}))
			)

			-- Auto-trigger completion
			wilder.set_option("use_python_remote_plugin", 0)
		end,
	},
}
