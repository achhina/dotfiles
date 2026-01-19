return {
	-- Mini.nvim - only for features that snacks doesn't provide well
	{
		"nvim-mini/mini.nvim",
		config = function()
			-- Better Around/Inside textobjects (snacks doesn't have this)
			-- Examples: va), viq, daf, etc.
			require("mini.ai").setup({
				n_lines = 500,
				custom_textobjects = {
					o = require("mini.ai").gen_spec.treesitter({
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}, {}),
					f = require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
					c = require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
					t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
					d = { "%f[%d]%d+" },
					e = {
						{
							"%u[%l%d]+%f[^%l%d]",
							"%f[%S][%l%d]+%f[^%l%d]",
							"%f[%P][%l%d]+%f[^%l%d]",
							"^[%l%d]+%f[^%l%d]",
						},
						"^().*()$",
					},
					g = function()
						local from = { line = 1, col = 1 }
						local to = {
							line = vim.fn.line("$"),
							col = math.max(vim.fn.getline("$"):len(), 1),
						}
						return { from = from, to = to }
					end,
				},
			})

			-- Enhanced commenting with treesitter support (snacks doesn't have commenting)
			-- Note: which-key will show overlap warning for 'gc' with 'gcc'
			-- This is expected behavior - 'gc' is an operator (gc{motion}),
			-- while 'gcc' is a direct line comment mapping
			require("mini.comment").setup({
				options = {
					custom_commentstring = function()
						-- Use built-in commentstring or treesitter if available
						local success, ts_commentstring = pcall(require, "ts_context_commentstring.internal")
						if success then
							return ts_commentstring.calculate_commentstring() or vim.bo.commentstring
						else
							return vim.bo.commentstring
						end
					end,
				},
				mappings = {
					comment = "gc",
					comment_line = "gcc",
					comment_visual = "gc",
					textobject = "gc",
				},
			})

			-- Statusline (snacks doesn't have statusline)
			local statusline = require("mini.statusline")
			statusline.setup({
				use_icons = true,
				set_vim_settings = true,
				content = {
					active = function()
						-- Show terminal info for terminal buffers
						if vim.bo.buftype == "terminal" then
							local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
							return "%#MiniStatuslineModeNormal# TERMINAL %#MiniStatuslineFilename# " .. cwd .. " %="
						end
						-- Use default content for other buffers
						return statusline.section_mode({ trunc_width = 120 })
							.. statusline.section_git({ trunc_width = 40 })
							.. statusline.section_diff({ trunc_width = 75 })
							.. statusline.section_diagnostics({ trunc_width = 75 })
							.. "%<"
							.. statusline.section_filename({ trunc_width = 140 })
							.. "%="
							.. statusline.section_fileinfo({ trunc_width = 120 })
							.. statusline.section_location({ trunc_width = 75 })
							.. statusline.section_searchcount({ trunc_width = 75 })
					end,
					inactive = function()
						-- Show minimal terminal info for inactive terminal buffers
						if vim.bo.buftype == "terminal" then
							return "%#MiniStatuslineInactive# TERMINAL %="
						end
						-- Use simple content for inactive windows
						return "%#MiniStatuslineFilename#%F%="
					end,
				},
			})

			-- Session management handled by auto-session plugin
		end,
	},
}
