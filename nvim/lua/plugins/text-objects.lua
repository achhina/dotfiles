return {
	-- Enhanced text objects
	{
		"echasnovski/mini.ai",
		event = "VeryLazy",
		config = function()
			local ai = require("mini.ai")
			ai.setup({
				-- Table with textobject id as fields, textobject specification as values.
				-- Also use this to disable builtin textobjects. See |MiniAi.config|.
				custom_textobjects = {
					-- Whole buffer
					e = function()
						local from = { line = 1, col = 1 }
						local to = {
							line = vim.fn.line("$"),
							col = math.max(vim.fn.getline("$"):len(), 1),
						}
						return { from = from, to = to }
					end,

					-- Function calls
					F = ai.gen_spec.function_call(),

					-- Arguments
					A = ai.gen_spec.argument(),

					-- Brackets
					B = { { "%b()", "%b[]", "%b{}" }, "^.%s*().-()%s*.$" },

					-- Digits
					d = { "%f[%d]%d+" },

					-- Entire line
					l = function(ai_type)
						local line_num = vim.fn.line(".")
						local line = vim.fn.getline(line_num)
						-- For `a` type, include the newline character
						if ai_type == "a" then
							return { from = { line = line_num, col = 1 }, to = { line = line_num + 1, col = 0 } }
						end
						-- For `i` type, exclude leading/trailing whitespace
						local first_col, last_col = line:find("^%s*"), line:find("%s*$")
						return {
							from = { line = line_num, col = (first_col and last_col and first_col or 1) },
							to = { line = line_num, col = (last_col and last_col > first_col and last_col or #line) },
						}
					end,

					-- Indentation
					I = function(ai_type)
						local indent_line = vim.fn.line(".")
						local indent_level = vim.fn.indent(indent_line)

						-- Find the range of lines with the same or greater indentation
						local start_line = indent_line
						local end_line = indent_line

						-- Find start of indentation block
						for i = indent_line - 1, 1, -1 do
							local line_indent = vim.fn.indent(i)
							if line_indent < indent_level and vim.fn.getline(i):match("^%s*$") == nil then
								break
							end
							if line_indent >= indent_level then
								start_line = i
							end
						end

						-- Find end of indentation block
						for i = indent_line + 1, vim.fn.line("$") do
							local line_indent = vim.fn.indent(i)
							if line_indent < indent_level and vim.fn.getline(i):match("^%s*$") == nil then
								break
							end
							if line_indent >= indent_level then
								end_line = i
							end
						end

						-- For `a` type, include surrounding lines
						if ai_type == "a" then
							start_line = math.max(1, start_line - 1)
							end_line = math.min(vim.fn.line("$"), end_line + 1)
						end

						return {
							from = { line = start_line, col = 1 },
							to = { line = end_line, col = #vim.fn.getline(end_line) },
						}
					end,

					-- URLs
					u = { "https?://[%w_.~!*:@&+$/?%%#-]+" },

					-- Markdown code blocks
					m = { "```.-```" },

					-- Treesitter-based text objects
					o = ai.gen_spec.treesitter({
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}),
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
					t = ai.gen_spec.treesitter({
						a = "@class.outer",
						i = "@class.inner",
					}),
					a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
				},

				-- Module mappings. Use `''` (empty string) to disable one.
				mappings = {
					-- Main textobject prefixes
					around = "a",
					inside = "i",

					-- Next/last variants
					around_next = "an",
					inside_next = "in",
					around_last = "al",
					inside_last = "il",

					-- Move cursor to corresponding edge of `a` textobject
					goto_left = "g[",
					goto_right = "g]",
				},

				-- Number of lines within which textobject is searched
				n_lines = 50,

				-- How to search for object (first inside current line, then inside
				-- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
				-- 'cover_or_nearest', 'next', 'prev', 'nearest'.
				search_method = "cover_or_next",

				-- Whether to disable showing non-error feedback
				silent = false,
			})
		end,
	},

	-- Enhanced surround operations
	{
		"echasnovski/mini.surround",
		event = "VeryLazy",
		config = function()
			require("mini.surround").setup({
				-- Add custom surroundings to be used on top of builtin ones. For more
				-- information with examples, see `:h MiniSurround.config`.
				custom_surroundings = {
					-- Lua function call
					f = {
						input = { "()%f[%w_]", "%f[%w_]%b()" },
						output = { left = "function() ", right = " end" },
					},
					-- Markdown code block
					c = {
						input = { "```.-```" },
						output = { left = "```\n", right = "\n```" },
					},
					-- HTML/XML tags
					t = {
						input = { "<(%w+)[^>]*>.*</%1>", "^<.->().*()</.*>$" },
						output = function()
							local tag = vim.fn.input("Tag name: ")
							if tag == "" then
								return nil
							end
							return { left = "<" .. tag .. ">", right = "</" .. tag .. ">" }
						end,
					},
				},

				-- Duration (in ms) of highlight when calling `MiniSurround.highlight()`
				highlight_duration = 500,

				-- Module mappings. Use `''` (empty string) to disable one.
				mappings = {
					add = "gsa", -- Add surrounding in Normal and Visual modes
					delete = "gsd", -- Delete surrounding
					find = "gsf", -- Find surrounding (to the right)
					find_left = "gsF", -- Find surrounding (to the left)
					highlight = "gsh", -- Highlight surrounding
					replace = "gsr", -- Replace surrounding
					update_n_lines = "gsn", -- Update `n_lines`

					suffix_last = "l", -- Suffix to search with "prev" method
					suffix_next = "n", -- Suffix to search with "next" method
				},

				-- Number of lines within which surrounding is searched
				n_lines = 20,

				-- Whether to respect selection type:
				-- - Place surroundings on separate lines in linewise mode.
				-- - Place surroundings on each line in blockwise mode.
				respect_selection_type = false,

				-- How to search for surrounding (first inside current line, then inside
				-- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
				-- 'cover_or_nearest', 'next', 'prev', 'nearest'. For more info, see
				-- `:h MiniSurround.config`.
				search_method = "cover",

				-- Whether to disable showing non-error feedback
				silent = false,
			})
		end,
	},

	-- Better word motions
	{
		"chrisgrieser/nvim-spider",
		event = "VeryLazy",
		keys = {
			{
				"w",
				"<cmd>lua require('spider').motion('w')<CR>",
				mode = { "n", "o", "x" },
				desc = "Spider-w",
			},
			{
				"e",
				"<cmd>lua require('spider').motion('e')<CR>",
				mode = { "n", "o", "x" },
				desc = "Spider-e",
			},
			{
				"b",
				"<cmd>lua require('spider').motion('b')<CR>",
				mode = { "n", "o", "x" },
				desc = "Spider-b",
			},
		},
		config = function()
			require("spider").setup({
				skipInsignificantPunctuation = true,
				consistentOperatorPending = false, -- see "Consistent Operator-pending Mode" in the README
				subwordMovement = true,
				customPatterns = {}, -- check "Custom Movement Patterns" in the README for details
			})
		end,
	},

	-- Exchange text objects
	{
		"gbprod/substitute.nvim",
		event = "VeryLazy",
		keys = {
			{
				"s",
				function()
					require("substitute").operator()
				end,
				mode = "n",
				desc = "Substitute with motion",
			},
			{
				"ss",
				function()
					require("substitute").line()
				end,
				mode = "n",
				desc = "Substitute line",
			},
			{
				"S",
				function()
					require("substitute").eol()
				end,
				mode = "n",
				desc = "Substitute to end of line",
			},
			{
				"s",
				function()
					require("substitute").visual()
				end,
				mode = "x",
				desc = "Substitute in visual mode",
			},
			-- Exchange
			{
				"sx",
				function()
					require("substitute.exchange").operator()
				end,
				mode = "n",
				desc = "Exchange with motion",
			},
			{
				"sxx",
				function()
					require("substitute.exchange").line()
				end,
				mode = "n",
				desc = "Exchange line",
			},
			{
				"X",
				function()
					require("substitute.exchange").visual()
				end,
				mode = "x",
				desc = "Exchange in visual mode",
			},
			{
				"sxc",
				function()
					require("substitute.exchange").cancel()
				end,
				mode = "n",
				desc = "Cancel exchange",
			},
		},
		config = function()
			require("substitute").setup({
				on_substitute = nil,
				yank_substituted_text = false,
				preserve_cursor_position = false,
				modifiers = nil,
				highlight_substituted_text = {
					enabled = true,
					timer = 500,
				},
				range = {
					prefix = "s",
					prompt_current_text = false,
					confirm = false,
					complete_word = false,
					subject = nil,
					range = nil,
					suffix = "",
				},
				exchange = {
					motion = false,
					use_esc_to_cancel = true,
					preserve_cursor_position = false,
					highlight_substituted_text = {
						enabled = true,
						timer = 500,
					},
				},
			})
		end,
	},

	-- Enhanced increment/decrement
	{
		"monaqa/dial.nvim",
		event = "VeryLazy",
		keys = {
			{
				"<C-a>",
				function()
					require("dial.map").manipulate("increment", "normal")
				end,
				mode = "n",
				desc = "Increment",
			},
			{
				"<C-x>",
				function()
					require("dial.map").manipulate("decrement", "normal")
				end,
				mode = "n",
				desc = "Decrement",
			},
			{
				"g<C-a>",
				function()
					require("dial.map").manipulate("increment", "gnormal")
				end,
				mode = "n",
				desc = "Increment",
			},
			{
				"g<C-x>",
				function()
					require("dial.map").manipulate("decrement", "gnormal")
				end,
				mode = "n",
				desc = "Decrement",
			},
			{
				"<C-a>",
				function()
					require("dial.map").manipulate("increment", "visual")
				end,
				mode = "v",
				desc = "Increment",
			},
			{
				"<C-x>",
				function()
					require("dial.map").manipulate("decrement", "visual")
				end,
				mode = "v",
				desc = "Decrement",
			},
			{
				"g<C-a>",
				function()
					require("dial.map").manipulate("increment", "gvisual")
				end,
				mode = "v",
				desc = "Increment",
			},
			{
				"g<C-x>",
				function()
					require("dial.map").manipulate("decrement", "gvisual")
				end,
				mode = "v",
				desc = "Decrement",
			},
		},
		config = function()
			local augend = require("dial.augend")
			require("dial.config").augends:register_group({
				-- default augments used when no group name is specified
				default = {
					augend.integer.alias.decimal, -- nonnegative decimal number (0, 1, 2, 3, ...)
					augend.integer.alias.hex, -- nonnegative hex number  (0x01, 0x1a1f, etc.)
					augend.date.alias["%Y/%m/%d"], -- date (2022/02/19, etc.)
					augend.constant.alias.bool, -- boolean value (true <-> false)
					augend.semver.alias.semver, -- semver (1.2.3)
					augend.constant.new({
						elements = { "and", "or" },
						word = true, -- if false, "sand" is incremented into "sor", "doctor" into "doctand", etc.
						cyclic = true, -- "or" is incremented into "and".
					}),
					augend.constant.new({
						elements = { "&&", "||" },
						word = false,
						cyclic = true,
					}),
					augend.constant.new({
						elements = { "yes", "no" },
						word = true,
						cyclic = true,
					}),
					augend.constant.new({
						elements = { "True", "False" },
						word = true,
						cyclic = true,
					}),
					augend.constant.new({
						elements = { "public", "private", "protected" },
						word = true,
						cyclic = true,
					}),
					augend.constant.new({
						elements = { "const", "let", "var" },
						word = true,
						cyclic = true,
					}),
				},
				visual = {
					augend.integer.alias.decimal,
					augend.integer.alias.hex,
					augend.date.alias["%Y/%m/%d"],
					augend.constant.alias.alpha,
					augend.constant.alias.Alpha,
				},
			})
		end,
	},

	-- Multiple cursors
	{
		"mg979/vim-visual-multi",
		event = "VeryLazy",
		init = function()
			vim.g.VM_maps = {
				["Find Under"] = "<C-d>",
				["Find Subword Under"] = "<C-d>",
				["Select All"] = "<C-S-d>",
				["Select h"] = "<S-Left>",
				["Select l"] = "<S-Right>",
				["Add Cursor Down"] = "<C-Down>",
				["Add Cursor Up"] = "<C-Up>",
				["Mouse Cursor"] = "<C-LeftMouse>",
				["Mouse Word"] = "<C-RightMouse>",
				["Mouse Column"] = "<M-C-RightMouse>",
			}
			vim.g.VM_leader = "\\"
			vim.g.VM_theme = "iceblue"
			vim.g.VM_highlight_matches = "underline"
		end,
	},
}
