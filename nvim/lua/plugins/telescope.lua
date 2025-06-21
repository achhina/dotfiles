return {
	-- Fuzzy Finder (files, lsp, etc)
	{ "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },

	-- Fuzzy Finder Algorithm which requires local dependencies to be built.
	-- Only load if `make` is available. Make sure you have the system
	-- requirements installed.
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		-- NOTE: If you are having trouble with this installation,
		--       refer to the README for telescope-fzf-native for more instructions.
		build = "make",
		cond = function()
			return vim.fn.executable("make") == 1
		end,

		config = function()
			-- [[ Configure Telescope ]]
			require("telescope").setup({
				defaults = {
					prompt_prefix = " ",
					selection_caret = " ",
					path_display = { "truncate" },
					file_ignore_patterns = {
						"^.git/",
						"^./.git/",
						"node_modules",
						"%.jpg",
						"%.jpeg",
						"%.png",
						"%.svg",
						"%.otf",
						"%.ttf",
						"%.lock",
					},
					layout_config = {
						horizontal = {
							prompt_position = "top",
							preview_width = 0.55,
							results_width = 0.8,
						},
						vertical = {
							mirror = false,
						},
						width = 0.87,
						height = 0.80,
						preview_cutoff = 120,
					},
					sorting_strategy = "ascending",
					winblend = 0,
					border = {},
					borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
					color_devicons = true,
					use_less = true,
					set_env = { ["COLORTERM"] = "truecolor" },
					mappings = {
						i = {
							["<C-n>"] = require("telescope.actions").move_selection_next,
							["<C-p>"] = require("telescope.actions").move_selection_previous,
							["<C-c>"] = require("telescope.actions").close,
							["<Down>"] = require("telescope.actions").move_selection_next,
							["<Up>"] = require("telescope.actions").move_selection_previous,
							["<CR>"] = require("telescope.actions").select_default,
							["<C-x>"] = require("telescope.actions").select_horizontal,
							["<C-v>"] = require("telescope.actions").select_vertical,
							["<C-t>"] = require("telescope.actions").select_tab,
							["<C-u>"] = require("telescope.actions").preview_scrolling_up,
							["<C-d>"] = require("telescope.actions").preview_scrolling_down,
							["<PageUp>"] = require("telescope.actions").results_scrolling_up,
							["<PageDown>"] = require("telescope.actions").results_scrolling_down,
							["<Tab>"] = require("telescope.actions").toggle_selection
								+ require("telescope.actions").move_selection_worse,
							["<S-Tab>"] = require("telescope.actions").toggle_selection
								+ require("telescope.actions").move_selection_better,
							["<C-q>"] = require("telescope.actions").send_to_qflist
								+ require("telescope.actions").open_qflist,
							["<M-q>"] = require("telescope.actions").send_selected_to_qflist
								+ require("telescope.actions").open_qflist,
							["<C-l>"] = require("telescope.actions").complete_tag,
							["<C-_>"] = require("telescope.actions").which_key, -- keys from pressing <C-/>
						},
						n = {
							["<esc>"] = require("telescope.actions").close,
							["<CR>"] = require("telescope.actions").select_default,
							["<C-x>"] = require("telescope.actions").select_horizontal,
							["<C-v>"] = require("telescope.actions").select_vertical,
							["<C-t>"] = require("telescope.actions").select_tab,
							["<Tab>"] = require("telescope.actions").toggle_selection
								+ require("telescope.actions").move_selection_worse,
							["<S-Tab>"] = require("telescope.actions").toggle_selection
								+ require("telescope.actions").move_selection_better,
							["<C-q>"] = require("telescope.actions").send_to_qflist
								+ require("telescope.actions").open_qflist,
							["<M-q>"] = require("telescope.actions").send_selected_to_qflist
								+ require("telescope.actions").open_qflist,
							["j"] = require("telescope.actions").move_selection_next,
							["k"] = require("telescope.actions").move_selection_previous,
							["H"] = require("telescope.actions").move_to_top,
							["M"] = require("telescope.actions").move_to_middle,
							["L"] = require("telescope.actions").move_to_bottom,
							["<Down>"] = require("telescope.actions").move_selection_next,
							["<Up>"] = require("telescope.actions").move_selection_previous,
							["gg"] = require("telescope.actions").move_to_top,
							["G"] = require("telescope.actions").move_to_bottom,
							["<C-u>"] = require("telescope.actions").preview_scrolling_up,
							["<C-d>"] = require("telescope.actions").preview_scrolling_down,
							["<PageUp>"] = require("telescope.actions").results_scrolling_up,
							["<PageDown>"] = require("telescope.actions").results_scrolling_down,
							["?"] = require("telescope.actions").which_key,
						},
					},
				},
				pickers = {
					find_files = {
						theme = "dropdown",
						previewer = false,
					},
					live_grep = {
						additional_args = function()
							return { "--hidden" }
						end,
					},
					buffers = {
						theme = "dropdown",
						previewer = false,
						initial_mode = "normal",
						mappings = {
							i = {
								["<C-d>"] = require("telescope.actions").delete_buffer,
							},
							n = {
								["dd"] = require("telescope.actions").delete_buffer,
							},
						},
					},
					planets = {
						show_pluto = true,
						show_moon = true,
					},
					colorscheme = {
						enable_preview = true,
					},
					lsp_references = {
						theme = "dropdown",
						initial_mode = "normal",
					},
					lsp_definitions = {
						theme = "dropdown",
						initial_mode = "normal",
					},
					lsp_declarations = {
						theme = "dropdown",
						initial_mode = "normal",
					},
					lsp_implementations = {
						theme = "dropdown",
						initial_mode = "normal",
					},
				},
			})

			-- Enable telescope fzf native, if installed
			pcall(require("telescope").load_extension, "fzf")

			-- See `:help telescope.builtin`
			vim.keymap.set(
				"n",
				"<leader>fr",
				require("telescope.builtin").oldfiles,
				{ desc = "[?] Find recently opened files" }
			)
			vim.keymap.set(
				"n",
				"<leader><space>",
				require("telescope.builtin").buffers,
				{ desc = "[ ] Find existing buffers" }
			)
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to telescope to change theme, layout, etc.
				require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			vim.keymap.set("n", "<leader>gf", require("telescope.builtin").git_files, { desc = "Search [G]it [F]iles" })
			vim.keymap.set("n", "<leader>sf", function()
				require("telescope.builtin").find_files()
			end, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>Sf", function()
				require("telescope.builtin").find_files({ hidden = true, no_ignore = true })
			end, { desc = "[S]earch [F]iles including hidden & ignored" })
			vim.keymap.set("n", "<leader>sF", function()
				require("telescope.builtin").find_files({
					cwd = require("telescope.utils").buffer_dir(),
				})
			end, { desc = "[S]earch [F]iles from buffer cwd" })
			vim.keymap.set("n", "<leader>SF", function()
				require("telescope.builtin").find_files({
					cwd = require("telescope.utils").buffer_dir(),
					hidden = true,
					no_ignore = true,
				})
			end, { desc = "[S]earch [F]iles from buffer cwd including hidden & ignored" })
			vim.keymap.set("n", "<leader>sh", require("telescope.builtin").help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set(
				"n",
				"<leader>sw",
				require("telescope.builtin").grep_string,
				{ desc = "[S]earch current [W]ord" }
			)
			vim.keymap.set("n", "<leader>sg", require("telescope.builtin").live_grep, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", "<leader>sG", function()
				require("telescope.builtin").live_grep({ cwd = require("telescope.utils").buffer_dir() })
			end, { desc = "[S]earch by [G]rep from buffer cwd" })
			vim.keymap.set(
				"n",
				"<leader>sd",
				require("telescope.builtin").diagnostics,
				{ desc = "[S]earch [D]iagnostics" }
			)

			-- Diagnostic keymaps
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
			vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })

			-- Spell Check Keymaps
			vim.keymap.set(
				"n",
				"<leader>ss",
				require("telescope.builtin").spell_suggest,
				{ desc = "[S]pell [S]uggestions" }
			)

			-- Additional useful pickers
			vim.keymap.set("n", "<leader>sc", require("telescope.builtin").commands, { desc = "[S]earch [C]ommands" })
			vim.keymap.set("n", "<leader>sk", require("telescope.builtin").keymaps, { desc = "[S]earch [K]eymaps" })
			vim.keymap.set("n", "<leader>sr", require("telescope.builtin").registers, { desc = "[S]earch [R]egisters" })
			vim.keymap.set("n", "<leader>sm", require("telescope.builtin").marks, { desc = "[S]earch [M]arks" })
			vim.keymap.set("n", "<leader>sj", require("telescope.builtin").jumplist, { desc = "[S]earch [J]umplist" })
			vim.keymap.set("n", "<leader>so", require("telescope.builtin").vim_options, { desc = "[S]earch [O]ptions" })
			vim.keymap.set("n", "<leader>st", require("telescope.builtin").colorscheme, { desc = "[S]earch [T]hemes" })
			vim.keymap.set(
				"n",
				"<leader>sb",
				require("telescope.builtin").current_buffer_fuzzy_find,
				{ desc = "[S]earch in [B]uffer" }
			)

			-- Git pickers
			vim.keymap.set("n", "<leader>gc", require("telescope.builtin").git_commits, { desc = "[G]it [C]ommits" })
			vim.keymap.set("n", "<leader>gb", require("telescope.builtin").git_branches, { desc = "[G]it [B]ranches" })
			vim.keymap.set("n", "<leader>gs", require("telescope.builtin").git_status, { desc = "[G]it [S]tatus" })
			vim.keymap.set("n", "<leader>gt", require("telescope.builtin").git_stash, { desc = "[G]it s[T]ash" })

			-- LSP pickers
			vim.keymap.set(
				"n",
				"<leader>lr",
				require("telescope.builtin").lsp_references,
				{ desc = "[L]SP [R]eferences" }
			)
			vim.keymap.set(
				"n",
				"<leader>ld",
				require("telescope.builtin").lsp_definitions,
				{ desc = "[L]SP [D]efinitions" }
			)
			vim.keymap.set(
				"n",
				"<leader>li",
				require("telescope.builtin").lsp_implementations,
				{ desc = "[L]SP [I]mplementations" }
			)
			vim.keymap.set(
				"n",
				"<leader>lt",
				require("telescope.builtin").lsp_type_definitions,
				{ desc = "[L]SP [T]ype definitions" }
			)
			vim.keymap.set(
				"n",
				"<leader>ls",
				require("telescope.builtin").lsp_document_symbols,
				{ desc = "[L]SP document [S]ymbols" }
			)
			vim.keymap.set(
				"n",
				"<leader>lS",
				require("telescope.builtin").lsp_workspace_symbols,
				{ desc = "[L]SP workspace [S]ymbols" }
			)

			-- Resume last picker
			vim.keymap.set("n", "<leader>sR", require("telescope.builtin").resume, { desc = "[S]earch [R]esume" })
		end,
	},
}
