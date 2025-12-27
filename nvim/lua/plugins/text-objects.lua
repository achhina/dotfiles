return {
	{
		"nvim-mini/mini.ai",
		event = "VeryLazy",
		config = function()
			local ai = require("mini.ai")
			ai.setup({
				custom_textobjects = {
					e = function()
						local from = { line = 1, col = 1 }
						local to = {
							line = vim.fn.line("$"),
							col = math.max(vim.fn.getline("$"):len(), 1),
						}
						return { from = from, to = to }
					end,

					F = ai.gen_spec.function_call(),
					A = ai.gen_spec.argument(),
					B = { { "%b()", "%b[]", "%b{}" }, "^.%s*().-()%s*.$" },
					d = { "%f[%d]%d+" },

					l = function(ai_type)
						local line_num = vim.fn.line(".")
						local line = vim.fn.getline(line_num)
						-- For `a` type, include the newline character
						if ai_type == "a" then
							return { from = { line = line_num, col = 1 }, to = { line = line_num + 1, col = 0 } }
						end
						-- For `i` type, exclude leading/trailing whitespace
						local content_start = line:match("^%s*()") or 1
						local content_end = (line:match("()%s*$") or (#line + 1)) - 1
						-- Handle edge case where line is all whitespace
						if content_start > content_end then
							content_start = 1
							content_end = 1
						end
						return {
							from = { line = line_num, col = content_start },
							to = { line = line_num, col = content_end },
						}
					end,

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

					u = { "https?://[%w%.~:/?#%[%]@!$&'()*+,;=%%-]+" },
					m = { "```[%s%S]-```" },

					o = ai.gen_spec.treesitter({
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}),
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
				},

				mappings = {
					around = "a",
					inside = "i",
					around_next = "",
					inside_next = "",
					around_last = "",
					inside_last = "",
					goto_left = "g[",
					goto_right = "g]",
				},

				n_lines = 50,
				search_method = "cover_or_next",
				silent = false,
			})
		end,
	},

	{
		"nvim-mini/mini.surround",
		event = "VeryLazy",
		config = function()
			require("mini.surround").setup({
				custom_surroundings = {
					c = {
						input = { "```[%s%S]-```" },
						output = { left = "```\n", right = "\n```" },
					},
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

				highlight_duration = 500,

				mappings = {
					add = "gsa",
					delete = "gsd",
					find = "gsf",
					find_left = "gsF",
					highlight = "gsh",
					replace = "gsr",
					update_n_lines = "gsn",
					suffix_last = "l",
					suffix_next = "n",
				},

				n_lines = 20,
				respect_selection_type = false,
				search_method = "cover",
				silent = false,
			})
		end,
	},

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
				consistentOperatorPending = false,
				subwordMovement = true,
				customPatterns = {},
			})
		end,
	},

	{
		"monaqa/dial.nvim",
		event = "VeryLazy",
		keys = (function()
			local keys = {}
			local mappings = {
				{ key = "<C-a>", op = "increment", dial_mode = "normal", vim_mode = "n" },
				{ key = "<C-x>", op = "decrement", dial_mode = "normal", vim_mode = "n" },
				{ key = "g<C-a>", op = "increment", dial_mode = "gnormal", vim_mode = "n" },
				{ key = "g<C-x>", op = "decrement", dial_mode = "gnormal", vim_mode = "n" },
				{ key = "<C-a>", op = "increment", dial_mode = "visual", vim_mode = "v" },
				{ key = "<C-x>", op = "decrement", dial_mode = "visual", vim_mode = "v" },
				{ key = "g<C-a>", op = "increment", dial_mode = "gvisual", vim_mode = "v" },
				{ key = "g<C-x>", op = "decrement", dial_mode = "gvisual", vim_mode = "v" },
			}
			for _, m in ipairs(mappings) do
				table.insert(keys, {
					m.key,
					function()
						require("dial.map").manipulate(m.op, m.dial_mode)
					end,
					mode = m.vim_mode,
					desc = m.op:sub(1, 1):upper() .. m.op:sub(2),
				})
			end
			return keys
		end)(),
		config = function()
			local augend = require("dial.augend")
			require("dial.config").augends:register_group({
				default = {
					augend.integer.alias.decimal,
					augend.integer.alias.hex,
					augend.date.alias["%Y/%m/%d"],
					augend.constant.alias.bool,
					augend.semver.alias.semver,
					augend.constant.new({
						elements = { "and", "or" },
						word = true,
						cyclic = true,
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
			})
		end,
	},

	{
		"mg979/vim-visual-multi",
		event = "VeryLazy",
		init = function()
			vim.g.VM_maps = {
				["Find Under"] = "<C-n>",
				["Find Subword Under"] = "<C-n>",
				["Select All"] = "<C-S-n>",
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
