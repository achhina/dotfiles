return {
	-- Breadcrumbs/context in winbar
	{
		"SmiteshP/nvim-navic",
		lazy = true,
		init = function()
			vim.g.navic_silence = true
		end,
		opts = {
			separator = " > ",
			highlight = true,
			depth_limit = 5,
			depth_limit_indicator = "..",
			safe_output = true,
			lazy_update_context = false,
			click = true,
			format_text = function(text)
				return text
			end,
		},
		config = function(_, opts)
			require("nvim-navic").setup(opts)

			-- Setup winbar to show breadcrumbs
			vim.api.nvim_create_autocmd({ "CursorMoved", "BufWinEnter", "BufFilePost" }, {
				callback = function()
					local navic = require("nvim-navic")
					if navic.is_available() then
						vim.opt_local.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
					else
						vim.opt_local.winbar = "%f" -- Fallback to filename
					end
				end,
			})
		end,
	},
}
