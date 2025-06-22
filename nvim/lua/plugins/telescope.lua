return {
	-- Telescope core - loads unconditionally
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = "Telescope",
		keys = {
			{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Find recently opened files" },
			{ "<leader><space>", "<cmd>Telescope buffers<cr>", desc = "Find existing buffers" },
			{ "<leader>sf", "<cmd>Telescope find_files<cr>", desc = "Search Files" },
			{ "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Search by Grep" },
			{ "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Search Help" },
			{ "<leader>sw", "<cmd>Telescope grep_string<cr>", desc = "Search current Word" },
			{ "<leader>sd", "<cmd>Telescope diagnostics<cr>", desc = "Search Diagnostics" },
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			-- Check if fzf-native is available
			local has_fzf = pcall(require, "telescope._extensions.fzf")

			telescope.setup({
				defaults = {
					prompt_prefix = " ",
					selection_caret = " ",
					path_display = { "truncate" },
					-- Use fzf sorters if available, otherwise fallback to default
					file_sorter = has_fzf and require("telescope.sorters").get_fzf_sorter
						or require("telescope.sorters").get_fuzzy_file,
					generic_sorter = has_fzf and require("telescope.sorters").get_generic_fzf_sorter
						or require("telescope.sorters").get_generic_fuzzy_sorter,
					-- Enhanced file ignore patterns for better performance
					file_ignore_patterns = {
						"^.git/",
						"^./.git/",
						"node_modules/",
						"%.jpg",
						"%.jpeg",
						"%.png",
						"%.svg",
						"%.gif",
						"%.webp",
						"%.otf",
						"%.ttf",
						"%.woff",
						"%.woff2",
						"%.lock",
						"__pycache__/",
						"%.pyc",
						".pytest_cache/",
						"target/", -- Rust
						"build/",
						"dist/",
						"%.min%.js",
						"%.min%.css",
						"%.bundle%.js",
						"coverage/",
						".nyc_output/",
						"vendor/",
						"%.zip",
						"%.tar",
						"%.tar%.gz",
						"%.rar",
						"%.7z",
						"%.class",
						"%.jar",
						"%.o",
						"%.a",
						"%.so",
						"%.dylib",
						"%.exe",
						"%.dll",
						"%.pdf",
						"%.doc",
						"%.docx",
					},
					-- Performance optimizations
					cache_picker = {
						num_pickers = 10,
						limit_entries = 1000,
					},
					layout_config = {
						horizontal = {
							prompt_position = "top",
							preview_width = 0.55,
							results_width = 0.8,
						},
						vertical = { mirror = false },
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
							["<C-n>"] = actions.move_selection_next,
							["<C-p>"] = actions.move_selection_previous,
							["<C-c>"] = actions.close,
							["<Down>"] = actions.move_selection_next,
							["<Up>"] = actions.move_selection_previous,
							["<CR>"] = actions.select_default,
							["<C-x>"] = actions.select_horizontal,
							["<C-v>"] = actions.select_vertical,
							["<C-t>"] = actions.select_tab,
							["<C-u>"] = actions.preview_scrolling_up,
							["<C-d>"] = actions.preview_scrolling_down,
							["<PageUp>"] = actions.results_scrolling_up,
							["<PageDown>"] = actions.results_scrolling_down,
							["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
							["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
							["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
							["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
							["<C-l>"] = actions.complete_tag,
							["<C-_>"] = actions.which_key,
						},
						n = {
							["<esc>"] = actions.close,
							["<CR>"] = actions.select_default,
							["<C-x>"] = actions.select_horizontal,
							["<C-v>"] = actions.select_vertical,
							["<C-t>"] = actions.select_tab,
							["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
							["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
							["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
							["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
							["j"] = actions.move_selection_next,
							["k"] = actions.move_selection_previous,
							["H"] = actions.move_to_top,
							["M"] = actions.move_to_middle,
							["L"] = actions.move_to_bottom,
							["<Down>"] = actions.move_selection_next,
							["<Up>"] = actions.move_selection_previous,
							["gg"] = actions.move_to_top,
							["G"] = actions.move_to_bottom,
							["<C-u>"] = actions.preview_scrolling_up,
							["<C-d>"] = actions.preview_scrolling_down,
							["<PageUp>"] = actions.results_scrolling_up,
							["<PageDown>"] = actions.results_scrolling_down,
							["?"] = actions.which_key,
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
							i = { ["<C-d>"] = actions.delete_buffer },
							n = { ["dd"] = actions.delete_buffer },
						},
					},
					colorscheme = { enable_preview = true },
					lsp_references = { theme = "dropdown", initial_mode = "normal" },
					lsp_definitions = { theme = "dropdown", initial_mode = "normal" },
					lsp_declarations = { theme = "dropdown", initial_mode = "normal" },
					lsp_implementations = { theme = "dropdown", initial_mode = "normal" },
				},
			})

			-- Try to load fzf extension if available
			pcall(telescope.load_extension, "fzf")

			-- Additional telescope keymaps
			local builtin = require("telescope.builtin")
			local utils = require("telescope.utils")
			local themes = require("telescope.themes")

			-- Buffer and file search
			vim.keymap.set("n", "<leader>/", function()
				builtin.current_buffer_fuzzy_find(themes.get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "Fuzzily search in current buffer" })

			-- File pickers
			vim.keymap.set("n", "<leader>gf", builtin.git_files, { desc = "Search Git Files" })
			vim.keymap.set("n", "<leader>Sf", function()
				builtin.find_files({ hidden = true, no_ignore = true })
			end, { desc = "Search Files including hidden & ignored" })
			vim.keymap.set("n", "<leader>sF", function()
				builtin.find_files({ cwd = utils.buffer_dir() })
			end, { desc = "Search Files from buffer cwd" })
			vim.keymap.set("n", "<leader>SF", function()
				builtin.find_files({ cwd = utils.buffer_dir(), hidden = true, no_ignore = true })
			end, { desc = "Search Files from buffer cwd including hidden & ignored" })

			-- Grep pickers
			vim.keymap.set("n", "<leader>sG", function()
				builtin.live_grep({ cwd = utils.buffer_dir() })
			end, { desc = "Search by Grep from buffer cwd" })

			-- Utility pickers
			vim.keymap.set("n", "<leader>sc", builtin.commands, { desc = "Search Commands" })
			vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "Search Keymaps" })
			vim.keymap.set("n", "<leader>sr", builtin.registers, { desc = "Search Registers" })
			vim.keymap.set("n", "<leader>sm", builtin.marks, { desc = "Search Marks" })
			vim.keymap.set("n", "<leader>sj", builtin.jumplist, { desc = "Search Jumplist" })
			vim.keymap.set("n", "<leader>so", builtin.vim_options, { desc = "Search Options" })
			vim.keymap.set("n", "<leader>st", builtin.colorscheme, { desc = "Search Themes" })
			vim.keymap.set("n", "<leader>sb", builtin.current_buffer_fuzzy_find, { desc = "Search in Buffer" })
			vim.keymap.set("n", "<leader>ss", builtin.spell_suggest, { desc = "Spell Suggestions" })

			-- Git pickers
			vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Git Commits" })
			vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Git Branches" })
			vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git Status" })
			vim.keymap.set("n", "<leader>gt", builtin.git_stash, { desc = "Git stash" })

			-- LSP pickers (these will be available globally)
			vim.keymap.set("n", "<leader>lr", builtin.lsp_references, { desc = "LSP References" })
			vim.keymap.set("n", "<leader>ld", builtin.lsp_definitions, { desc = "LSP Definitions" })
			vim.keymap.set("n", "<leader>li", builtin.lsp_implementations, { desc = "LSP Implementations" })
			vim.keymap.set("n", "<leader>lt", builtin.lsp_type_definitions, { desc = "LSP Type definitions" })
			vim.keymap.set("n", "<leader>ls", builtin.lsp_document_symbols, { desc = "LSP document Symbols" })
			vim.keymap.set("n", "<leader>lS", builtin.lsp_workspace_symbols, { desc = "LSP workspace Symbols" })

			-- Resume last picker
			vim.keymap.set("n", "<leader>sR", builtin.resume, { desc = "Search Resume" })

			-- Diagnostic keymaps
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
			vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
		end,
	},

	-- FZF native extension - optional, better performance when available
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
		build = "make",
		cond = function()
			-- Check if we have make or cmake available
			return vim.fn.executable("make") == 1 or vim.fn.executable("cmake") == 1
		end,
		config = function()
			-- Extension will be loaded automatically by telescope
			pcall(require("telescope").load_extension, "fzf")
		end,
	},

	-- Undo tree with telescope
	{
		"debugloop/telescope-undo.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
		keys = {
			{ "<leader>su", "<cmd>Telescope undo<cr>", desc = "Search Undo tree" },
		},
		config = function()
			pcall(require("telescope").load_extension, "undo")
		end,
	},
}
