return {
	-- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
		"nvim-treesitter/nvim-treesitter-context",
	},
	build = ":TSUpdate",
	config = function()
		-- [[ Configure Treesitter ]]
		require("nvim-treesitter.configs").setup({
			-- Comprehensive language support
			ensure_installed = {
				"bash",
				"c",
				"cpp",
				"css",
				"dockerfile",
				"go",
				"html",
				"javascript",
				"json",
				"lua",
				"markdown",
				"markdown_inline",
				"nix",
				"python",
				"regex",
				"rust",
				"toml",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"yaml",
			},

			-- Enable automatic installation for new filetypes
			auto_install = true,

			-- Enhanced highlighting with additional features
			highlight = {
				enable = true,
				-- Disable slow treesitter highlighting for large files
				disable = function(_, buf)
					local max_filesize = 100 * 1024 -- 100 KB
					local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > max_filesize then
						return true
					end
				end,
				-- Use additional vim regex highlighting
				additional_vim_regex_highlighting = false,
			},

			-- Better indentation
			indent = {
				enable = true,
				-- Disable for specific languages that have issues
				disable = { "python", "yaml" },
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<c-space>",
					node_incremental = "<c-space>",
					scope_incremental = "<c-s>",
					node_decremental = "<M-space>",
				},
			},
			-- Enhanced folding
			fold = {
				enable = true,
				disable = {},
			},

			-- Better textobjects with more comprehensive mappings
			textobjects = {
				select = {
					enable = true,
					lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
					keymaps = {
						-- Parameters/arguments
						["aa"] = "@parameter.outer",
						["ia"] = "@parameter.inner",
						-- Functions
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						-- Classes
						["ac"] = "@class.outer",
						["ic"] = "@class.inner",
						-- Conditionals
						["ai"] = "@conditional.outer",
						["ii"] = "@conditional.inner",
						-- Loops
						["al"] = "@loop.outer",
						["il"] = "@loop.inner",
						-- Comments
						["aC"] = "@comment.outer",
						["iC"] = "@comment.inner",
						-- Blocks
						["ab"] = "@block.outer",
						["ib"] = "@block.inner",
						-- Calls
						["aF"] = "@call.outer",
						["iF"] = "@call.inner",
					},
					-- Selection modes
					selection_modes = {
						["@parameter.outer"] = "v", -- charwise
						["@function.outer"] = "V", -- linewise
						["@class.outer"] = "V", -- linewise
					},
					-- Include surrounding whitespace
					include_surrounding_whitespace = true,
				},
				move = {
					enable = true,
					set_jumps = true, -- whether to set jumps in the jumplist
					goto_next_start = {
						["]m"] = "@function.outer",
						["]]"] = "@class.outer",
						["]i"] = "@conditional.outer",
						["]l"] = "@loop.outer",
						["]c"] = "@comment.outer",
					},
					goto_next_end = {
						["]M"] = "@function.outer",
						["]["] = "@class.outer",
						["]I"] = "@conditional.outer",
						["]L"] = "@loop.outer",
						["]C"] = "@comment.outer",
					},
					goto_previous_start = {
						["[m"] = "@function.outer",
						["[["] = "@class.outer",
						["[i"] = "@conditional.outer",
						["[l"] = "@loop.outer",
						["[c"] = "@comment.outer",
					},
					goto_previous_end = {
						["[M"] = "@function.outer",
						["[]"] = "@class.outer",
						["[I"] = "@conditional.outer",
						["[L"] = "@loop.outer",
						["[C"] = "@comment.outer",
					},
				},
				swap = {
					enable = true,
					swap_next = {
						["<leader>sa"] = "@parameter.inner",
						["<leader>sf"] = "@function.outer",
						["<leader>sc"] = "@class.outer",
					},
					swap_previous = {
						["<leader>sA"] = "@parameter.inner",
						["<leader>sF"] = "@function.outer",
						["<leader>sC"] = "@class.outer",
					},
				},
				-- LSP interop for better definitions
				lsp_interop = {
					enable = true,
					border = "none",
					floating_preview_opts = {},
					peek_definition_code = {
						["<leader>Pf"] = "@function.outer",
						["<leader>PF"] = "@class.outer",
					},
				},
			},

			-- Enable playground for testing
			playground = {
				enable = true,
				disable = {},
				updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
				persist_queries = false, -- Whether the query persists across vim sessions
				keybindings = {
					toggle_query_editor = "o",
					toggle_hl_groups = "i",
					toggle_injected_languages = "t",
					toggle_anonymous_nodes = "a",
					toggle_language_display = "I",
					focus_language = "f",
					unfocus_language = "F",
					update = "R",
					goto_node = "<cr>",
					show_help = "?",
				},
			},
		})

		-- Configure treesitter context with performance optimizations
		require("treesitter-context").setup({
			enable = true,
			max_lines = 3, -- Limit context lines for performance
			min_window_height = 10, -- Don't show context in small windows
			line_numbers = true,
			multiline_threshold = 2, -- Reduced threshold for better performance
			trim_scope = "outer",
			mode = "cursor",
			separator = nil,
			zindex = 20,
			-- Performance: disable for large files and certain file types
			on_attach = function(buf)
				-- Disable for large files
				local max_filesize = 100 * 1024 -- 100 KB
				local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
				if ok and stats and stats.size > max_filesize then
					return false
				end

				-- Disable for specific filetypes
				local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
				local excluded_filetypes = {
					"help",
					"alpha",
					"dashboard",
					"neo-tree",
					"lazy",
					"mason",
					"notify",
					"toggleterm",
					"lazyterm",
					"oil",
					"qf",
					"quickfix",
				}

				for _, ft in ipairs(excluded_filetypes) do
					if filetype == ft then
						return false
					end
				end

				return true
			end,
		})

		-- Additional performance optimizations
		-- Disable treesitter for very large buffers
		vim.api.nvim_create_autocmd({ "BufReadPre", "FileReadPre" }, {
			callback = function()
				local buf = vim.api.nvim_get_current_buf()
				local max_filesize = 500 * 1024 -- 500 KB
				local filename = vim.api.nvim_buf_get_name(buf)

				if filename == "" then
					return
				end

				local ok, stats = pcall(vim.loop.fs_stat, filename)
				if ok and stats and stats.size > max_filesize then
					vim.notify("Large file detected. Disabling treesitter for performance.", vim.log.levels.WARN)
					vim.api.nvim_buf_set_option(buf, "syntax", "off")
					vim.treesitter.stop(buf)
				end
			end,
		})
	end,
}
