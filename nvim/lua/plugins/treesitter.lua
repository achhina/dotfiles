return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
		"nvim-treesitter/nvim-treesitter-context",
	},
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
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
				"scss",
				"svelte",
				"toml",
				"tsx",
				"typescript",
				"typst",
				"vim",
				"vimdoc",
				"vue",
				"yaml",
			},

			auto_install = true,

			highlight = {
				enable = true,
				disable = function(_, buf)
					local max_filesize = 100 * 1024 -- 100 KB
					local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > max_filesize then
						return true
					end
				end,
				additional_vim_regex_highlighting = false,
			},

			indent = {
				enable = true,
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
			fold = {
				enable = true,
				disable = {},
			},

			textobjects = {
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["aa"] = "@parameter.outer",
						["ia"] = "@parameter.inner",
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						["ic"] = "@class.inner",
						["ai"] = "@conditional.outer",
						["ii"] = "@conditional.inner",
						["al"] = "@loop.outer",
						["il"] = "@loop.inner",
						["aC"] = "@comment.outer",
						["iC"] = "@comment.inner",
						["ab"] = "@block.outer",
						["ib"] = "@block.inner",
						["aF"] = "@call.outer",
						["iF"] = "@call.inner",
					},
					selection_modes = {
						["@parameter.outer"] = "v", -- charwise
						["@function.outer"] = "V", -- linewise
						["@class.outer"] = "V", -- linewise
					},
					include_surrounding_whitespace = true,
				},
				move = {
					enable = true,
					set_jumps = true,
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
						["<leader>swf"] = "@function.outer",
						["<leader>sc"] = "@class.outer",
					},
					swap_previous = {
						["<leader>sA"] = "@parameter.inner",
						["<leader>swF"] = "@function.outer",
						["<leader>sC"] = "@class.outer",
					},
				},
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

			playground = {
				enable = true,
				disable = {},
				updatetime = 25,
				persist_queries = false,
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

		require("treesitter-context").setup({
			enable = true,
			max_lines = 3,
			min_window_height = 10,
			line_numbers = true,
			multiline_threshold = 2,
			trim_scope = "outer",
			mode = "cursor",
			separator = nil,
			zindex = 20,
			on_attach = function(buf)
				local max_filesize = 100 * 1024
				local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
				if ok and stats and stats.size > max_filesize then
					return false
				end

				local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
				local excluded_filetypes = {
					"help",
					"alpha",
					"dashboard",
					"neo-tree",
					"lazy",
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

		vim.api.nvim_create_autocmd({ "BufReadPre", "FileReadPre" }, {
			callback = function()
				local buf = vim.api.nvim_get_current_buf()
				local max_filesize = 500 * 1024
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
