return {
	-- Better TODO management and highlighting
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = { "BufReadPost", "BufNewFile" },
		cmd = { "TodoTrouble", "TodoLocList", "TodoQuickFix" },
		keys = {
			{
				"<leader>st",
				function()
					-- Use fzf-lua to search for TODO comments
					require("fzf-lua").live_grep({
						prompt = "TODOs> ",
						cmd = "rg --column --line-number --no-heading --color=always --smart-case "
							.. "'\\b(TODO|HACK|WARN|PERF|NOTE|TEST|FIX|FIXME)\\b'",
					})
				end,
				desc = "Search TODOs",
			},
			{
				"<leader>sT",
				function()
					-- Search specific TODO keywords
					require("fzf-lua").live_grep({
						prompt = "TODO/FIX> ",
						cmd = "rg --column --line-number --no-heading --color=always --smart-case "
							.. "'\\b(TODO|FIX|FIXME)\\b'",
					})
				end,
				desc = "Search TODO/FIX/FIXME",
			},
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next todo comment",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous todo comment",
			},
		},
		config = function()
			require("todo-comments").setup({
				signs = true, -- show icons in the signs column
				sign_priority = 8, -- sign priority
				-- keywords recognized as todo comments
				keywords = {
					FIX = {
						icon = " ", -- icon used for the sign, and in search results
						color = "error", -- can be a hex color, or a named color (see below)
						alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
						-- signs = false, -- configure signs for some keywords individually
					},
					TODO = { icon = " ", color = "info" },
					HACK = { icon = " ", color = "warning" },
					WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
					PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
					NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
					TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
				},
				gui_style = {
					fg = "NONE", -- The gui style to use for the fg highlight group.
					bg = "BOLD", -- The gui style to use for the bg highlight group.
				},
				merge_keywords = true, -- when true, custom keywords will be merged with the defaults
				-- highlighting of the line containing the todo comment
				-- * before: highlights before the keyword (typically comment characters)
				-- * keyword: highlights of the keyword
				-- * after: highlights after the keyword (todo text)
				highlight = {
					multiline = true, -- enable multine todo comments
					multiline_pattern = "^.", -- lua pattern to match the next multiline from the start of the matched keyword
					multiline_context = 10, -- extra lines around the todo multiline for context
					before = "", -- "fg" or "bg" or empty
					keyword = "wide", -- highlight style options: "fg", "bg", "wide", "wide_bg", "wide_fg"
					after = "fg", -- "fg" or "bg" or empty
					pattern = [[.*<(KEYWORDS)\s*:]], -- pattern or table of patterns, used for highlighting (vim regex)
					comments_only = true, -- uses treesitter to match keywords in comments only
					max_line_len = 400, -- ignore lines longer than this
					exclude = {}, -- list of file types to exclude highlighting
				},
				-- list of named colors where we try to extract the guifg from the
				-- list of highlight groups or use the hex color if hl not found as a fallback
				colors = {
					error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
					warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
					info = { "DiagnosticInfo", "#2563EB" },
					hint = { "DiagnosticHint", "#10B981" },
					default = { "Identifier", "#7C3AED" },
					test = { "Identifier", "#FF006E" },
				},
				search = {
					command = "rg",
					args = {
						"--color=never",
						"--no-heading",
						"--with-filename",
						"--line-number",
						"--column",
					},
					-- regex that will be used to match keywords.
					-- don't replace the (KEYWORDS) placeholder
					pattern = [[\b(KEYWORDS):]], -- ripgrep regex
					-- pattern = [[\b(KEYWORDS)\b]], -- match without the extra colon. You'll likely get false positives
				},
			})

			-- Note: Using fzf-lua for TODO search functionality

			-- Set up autocommands for better workflow
			local todo_group = vim.api.nvim_create_augroup("TodoComments", { clear = true })

			-- Simple autocmd for todo highlighting refresh (using built-in vim mechanisms)
			vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
				group = todo_group,
				pattern = "*",
				callback = function()
					-- Simple highlight refresh using vim's built-in syntax refresh
					vim.defer_fn(function()
						vim.cmd("syntax sync fromstart")
					end, 50)
				end,
			})

			-- Show todo stats in status line (simplified version)
			_G.todo_count = function()
				-- Simple placeholder - todo-comments doesn't expose get_todos() API
				-- Could implement custom search if needed, but keeping it simple for now
				return ""
			end
		end,
	},
}
