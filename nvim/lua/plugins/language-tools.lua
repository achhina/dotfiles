return {
	-- TypeScript enhanced tools
	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
		config = function()
			require("typescript-tools").setup({
				on_attach = function(client, bufnr)
					-- Disable tsserver formatting in favor of prettier/eslint
					client.server_capabilities.documentFormattingProvider = false
					client.server_capabilities.documentRangeFormattingProvider = false

					-- Load LSP keymaps
					require("config.keymaps").load_lsp_keymaps(bufnr)

					-- TypeScript-specific keymaps
					local nmap = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "TS: " .. desc })
					end

					nmap("<leader>tsi", "<cmd>TSToolsOrganizeImports<cr>", "Organize imports")
					nmap("<leader>tss", "<cmd>TSToolsSortImports<cr>", "Sort imports")
					nmap("<leader>tsr", "<cmd>TSToolsRemoveUnusedImports<cr>", "Remove unused imports")
					nmap("<leader>tsf", "<cmd>TSToolsFixAll<cr>", "Fix all issues")
					nmap("<leader>tsa", "<cmd>TSToolsAddMissingImports<cr>", "Add missing imports")
					nmap("<leader>tsd", "<cmd>TSToolsGoToSourceDefinition<cr>", "Go to source definition")
					nmap("<leader>tsR", "<cmd>TSToolsFileReferences<cr>", "File references")
					nmap("<leader>tsn", "<cmd>TSToolsRenameFile<cr>", "Rename file")
				end,
				handlers = {
					-- Enhanced hover with TypeScript-specific information
					["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
						border = "rounded",
						max_width = 80,
					}),
				},
				settings = {
					-- Spawn additional tsserver instance to calculate diagnostics on it
					separate_diagnostic_server = true,
					-- "change"|"insert_leave" determine when the client asks the server about diagnostic
					publish_diagnostic_on = "insert_leave",
					-- Array of strings("fix_all"|"add_missing_imports"|"remove_unused"|
					-- "remove_unused_imports"|"organize_imports") -- or string "all"
					-- to include all supported code actions
					-- specify commands exposed as code_actions
					expose_as_code_action = "all",
					-- String|nil - specify a custom path to `tsserver.js` file, if this is nil or file under path
					-- not exists then standard path resolution strategy is applied
					tsserver_path = nil,
					-- Specify a list of plugins to load by tsserver, e.g., for support `styled-components`
					-- (see 💅 `styled-components` support section)
					tsserver_plugins = {},
					-- This value is passed to: https://nodejs.org/api/cli.html#--max-old-space-sizesize-in-megabytes
					-- Memory limit in megabytes or "auto"(basically no limit)
					tsserver_max_memory = 4096,
					-- Described below
					tsserver_format_options = {},
					tsserver_file_preferences = {
						includeInlayParameterNameHints = "literals", -- "none" | "literals" | "all"
						includeInlayParameterNameHintsWhenArgumentMatchesName = false,
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = true,
						includeInlayVariableTypeHintsWhenTypeMatchesName = false,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayEnumMemberValueHints = true,
					},
					-- Locale of all tsserver messages, supported locales:
					-- See TypeScript repo for full list
					tsserver_locale = "en",
					-- Mirror of VSCode's `typescript.suggest.completeFunctionCalls`
					complete_function_calls = false,
					include_completions_with_insert_text = true,
					-- CodeLens
					-- WARNING: Experimental feature also in VSCode, because it might hit performance of server.
					-- possible values: ("off"|"all"|"implementations_only"|"references_only")
					code_lens = "off",
					-- By default code lenses are displayed on all referencable values and for some of you it can
					-- be too much this option reduce count of them by removing member references from lenses
					disable_member_code_lens = true,
					-- JSXCloseTag
					-- WARNING: it is disabled by default (maybe you configuration or distro already uses nvim-ts-autotag,
					-- that maybe have a conflict if enable this feature. )
					jsx_close_tag = {
						enable = false,
						filetypes = { "javascriptreact", "typescriptreact" },
					},
				},
			})
		end,
	},

	-- Python virtual environment selector
	{
		"linux-cultist/venv-selector.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
			"mfussenegger/nvim-dap",
			"mfussenegger/nvim-dap-python", --optional
			"nvim-lua/plenary.nvim",
		},
		lazy = false,
		branch = "regexp", -- Use the regexp branch for better performance
		keys = {
			{
				"<leader>vs",
				"<cmd>VenvSelect<cr>",
				desc = "Select virtual environment",
			},
			{
				"<leader>vc",
				"<cmd>VenvSelectCached<cr>",
				desc = "Select cached virtual environment",
			},
		},
		config = function()
			require("venv-selector").setup({
				options = {
					notify_user_on_venv_activation = true,
				},
				search = {
					my_venvs = {
						command = "fd 'pyvenv.cfg' ~/.virtualenvs --max-depth 2",
					},
					pipenv = {
						command = "fd 'pyvenv.cfg' ~/.local/share/virtualenvs --max-depth 2",
					},
					poetry = {
						command = "fd 'pyvenv.cfg' ~/Library/Caches/pypoetry/virtualenvs --max-depth 2",
					},
					conda = {
						command = "fd 'pyvenv.cfg' ~/miniconda3/envs --max-depth 2",
					},
					pyenv = {
						command = "fd 'pyvenv.cfg' ~/.pyenv/versions --max-depth 2",
					},
					workspace = {
						command = "fd 'pyvenv.cfg' . --max-depth 4 --type f",
					},
				},
			})

			-- Auto-activate virtual environment when entering Python files
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "python",
				callback = function()
					-- Try to auto-detect and activate venv
					local venv_selector = require("venv-selector")
					if venv_selector.venv() == nil then
						-- Look for common venv indicators
						local venv_paths = { ".venv", "venv", ".env" }
						for _, path in ipairs(venv_paths) do
							if vim.fn.isdirectory(path) == 1 then
								require("venv-selector.cached_venv").retrieve()
								break
							end
						end
					end
				end,
			})
		end,
	},

	-- Enhanced Markdown support
	{
		"tadmccorkle/markdown.nvim",
		ft = "markdown",
		config = function()
			require("markdown").setup({
				mappings = {
					inline_surround_toggle = "gs", -- (string|boolean) toggle inline style
					inline_surround_toggle_line = "gss", -- (string|boolean) line-wise toggle inline style
					inline_surround_delete = "ds", -- (string|boolean) delete inline style
					inline_surround_change = "cs", -- (string|boolean) change inline style
					link_add = "gl", -- (string|boolean) add link
					link_follow = "gx", -- (string|boolean) follow link
					go_curr_heading = "]c", -- (string|boolean) set cursor to current section heading
					go_parent_heading = "]p", -- (string|boolean) set cursor to parent section heading
					go_next_heading = "]]", -- (string|boolean) set cursor to next section heading
					go_prev_heading = "[[", -- (string|boolean) set cursor to previous section heading
				},
				inline_surround = {
					-- For the emphasis, strong, strikethrough, and code fields:
					-- * 'key': used to specify an inline style in toggle, delete, and change operations
					-- * 'txt': text inserted when toggling or changing to the specified inline style
					emphasis = {
						key = "i",
						txt = "*",
					},
					strong = {
						key = "b",
						txt = "**",
					},
					strikethrough = {
						key = "s",
						txt = "~~",
					},
					code = {
						key = "c",
						txt = "`",
					},
				},
				link = {
					paste = {
						enable = true, -- whether to convert URLs to links on paste
					},
				},
				toc = {
					-- Comment text to flag headings/sections for omission in table of contents.
					omit_heading = "toc omit heading",
					omit_section = "toc omit section",
				},
				-- Hook functions allow for processing and transforming content before conversion
				hooks = {
					converting_html_to_markdown = {},
				},
			})
		end,
	},

	-- Better documentation generation
	{
		"danymat/neogen",
		dependencies = "nvim-treesitter/nvim-treesitter",
		cmd = "Neogen",
		keys = {
			{
				"<leader>ng",
				function()
					require("neogen").generate()
				end,
				desc = "Generate documentation",
			},
			{
				"<leader>nf",
				function()
					require("neogen").generate({ type = "func" })
				end,
				desc = "Generate function documentation",
			},
			{
				"<leader>nc",
				function()
					require("neogen").generate({ type = "class" })
				end,
				desc = "Generate class documentation",
			},
			{
				"<leader>nt",
				function()
					require("neogen").generate({ type = "type" })
				end,
				desc = "Generate type documentation",
			},
		},
		config = function()
			require("neogen").setup({
				enabled = true,
				input_after_comment = true, -- auto jump with insert mode on annotation
				-- Configuration for default languages
				languages = {
					python = {
						template = {
							annotation_convention = "google_docstrings",
						},
					},
					typescript = {
						template = {
							annotation_convention = "jsdoc",
						},
					},
					javascript = {
						template = {
							annotation_convention = "jsdoc",
						},
					},
					rust = {
						template = {
							annotation_convention = "rustdoc",
						},
					},
					go = {
						template = {
							annotation_convention = "godoc",
						},
					},
					lua = {
						template = {
							annotation_convention = "ldoc",
						},
					},
					java = {
						template = {
							annotation_convention = "javadoc",
						},
					},
					c = {
						template = {
							annotation_convention = "doxygen",
						},
					},
					cpp = {
						template = {
							annotation_convention = "doxygen",
						},
					},
				},
				-- Use treesitter to locate the cursor
				snippet_engine = "nvim",
			})
		end,
	},

	-- Database support
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
		},
		cmd = {
			"DBUI",
			"DBUIToggle",
			"DBUIAddConnection",
			"DBUIFindBuffer",
		},
		keys = {
			{ "<leader>D", "", desc = "+database" },
			{ "<leader>Db", "<cmd>DBUIToggle<cr>", desc = "Toggle DBUI" },
			{ "<leader>Df", "<cmd>DBUIFindBuffer<cr>", desc = "Find DB buffer" },
			{ "<leader>Dr", "<cmd>DBUIRenameBuffer<cr>", desc = "Rename DB buffer" },
			{ "<leader>Dq", "<cmd>DBUILastQueryInfo<cr>", desc = "Last query info" },
		},
		init = function()
			-- Your DBUI configuration
			vim.g.db_ui_use_nerd_fonts = 1
			vim.g.db_ui_winwidth = 40
			vim.g.db_ui_show_database_icon = 1
			vim.g.db_ui_force_echo_notifications = 1
			vim.g.db_ui_win_position = "left"
			vim.g.db_ui_use_nvim_notify = 1

			-- Better icons
			vim.g.db_ui_icons = {
				expanded = {
					db = "▾ ",
					buffers = "▾ ",
					saved_queries = "▾ ",
					schemas = "▾ ",
					schema = "▾ פּ",
					tables = "▾ 藺",
					table = "▾ ",
				},
				collapsed = {
					db = "▸ ",
					buffers = "▸ ",
					saved_queries = "▸ ",
					schemas = "▸ ",
					schema = "▸ פּ",
					tables = "▸ 藺",
					table = "▸ ",
				},
				saved_query = "",
				new_query = "璘",
				tables = "離",
				buffers = "﬘",
				add_connection = "",
				connection_ok = "✓",
				connection_error = "✕",
			}
		end,
		config = function()
			-- Auto-completion for SQL
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "sql", "mysql", "plsql" },
				callback = function()
					require("cmp").setup.buffer({ sources = { { name = "vim-dadbod-completion" } } })
				end,
			})
		end,
	},
}
