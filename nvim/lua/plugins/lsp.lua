return {
	-- LSP Configuration & Plugins
	"neovim/nvim-lspconfig",
	dependencies = {
		-- Enhanced LSP progress notifications
		{
			"j-hui/fidget.nvim",
			opts = {
				progress = {
					display = {
						render_limit = 16,
						done_ttl = 3,
						progress_style = "percentage",
					},
					ignore_done_already = false,
					ignore_empty_message = false,
				},
				notification = {
					window = {
						winblend = 0,
						border = "rounded",
						zindex = 45,
					},
					view = {
						stack_upwards = true,
						icon_separator = " ",
						group_separator = "---",
					},
				},
			},
		},
	},
	config = function()
		-- [[ Configure LSP ]]
		-- Enhanced LSP handlers and diagnostics
		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
			border = "rounded",
			max_width = 80,
			max_height = 20,
		})

		vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
			border = "rounded",
			silent = true,
		})

		-- Better diagnostics configuration
		vim.diagnostic.config({
			virtual_text = {
				severity = { min = vim.diagnostic.severity.WARN },
				source = "if_many",
				format = function(diagnostic)
					return string.format("%s (%s)", diagnostic.message, diagnostic.source)
				end,
			},
			float = { border = "rounded", source = "always" },
			signs = true,
			underline = true,
			update_in_insert = false,
			severity_sort = true,
		})

		-- Performance optimizations
		vim.lsp.set_log_level("WARN")
		vim.opt.updatetime = 250

		-- Memory management
		vim.g.lsp_zero_extend_cmp = 0

		-- Future optimization functions (currently unused)
		-- local function should_load_lsp(server, bufnr)
		-- 	local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
		-- 	local server_filetypes = {
		-- 		ts_ls = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
		-- 		pyright = { "python" },
		-- 		gopls = { "go" },
		-- 		rust_analyzer = { "rust" },
		-- 		lua_ls = { "lua" },
		-- 		clangd = { "c", "cpp", "objc", "objcpp" },
		-- 		marksman = { "markdown" },
		-- 		yamlls = { "yaml" },
		-- 		dockerls = { "dockerfile" },
		-- 		taplo = { "toml" },
		-- 	}
		-- 	return vim.tbl_contains(server_filetypes[server] or {}, filetype)
		-- end

		-- local function get_project_root()
		-- 	local patterns = { ".git", "package.json", "Cargo.toml", "go.mod", "pyproject.toml", "Makefile" }
		-- 	return vim.fs.dirname(vim.fs.find(patterns, { upward = true })[1])
		-- end

		-- Auto-organize imports and fix issues on save
		local format_augroup = vim.api.nvim_create_augroup("LSPFormatting", { clear = true })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = format_augroup,
			pattern = "*.ts,*.tsx,*.js,*.jsx,*.py,*.go,*.rs",
			callback = function()
				-- Try to organize imports and fix issues
				local params = vim.lsp.util.make_range_params()
				params.context = { only = { "source.organizeImports", "source.fixAll" } }

				local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
				if result then
					for _, res in pairs(result) do
						if res.result then
							for _, action in pairs(res.result) do
								if action.edit then
									vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
								elseif action.command then
									vim.lsp.buf.execute_command(action.command)
								end
							end
						end
					end
				end
			end,
		})

		--  This function gets run when an LSP connects to a particular buffer.
		local on_attach = function(client, bufnr)
			require("config.keymaps").load_lsp_keymaps(bufnr)

			-- Enable inlay hints if supported
			if client.supports_method("textDocument/inlayHint") then
				vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			end

			-- Document highlighting
			if client.supports_method("textDocument/documentHighlight") then
				local group = vim.api.nvim_create_augroup("LSPDocumentHighlight", { clear = false })
				vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
				vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
					buffer = bufnr,
					group = group,
					callback = vim.lsp.buf.document_highlight,
				})
				vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
					buffer = bufnr,
					group = group,
					callback = vim.lsp.buf.clear_references,
				})
			end
		end

		-- All servers now managed by Nix
		local nix_servers = {
			clangd = {},
			gopls = {
				gofumpt = true,
				staticcheck = true,
				usePlaceholders = true,
				analyses = {
					unusedparams = true,
					shadow = true,
					fieldalignment = false,
				},
				hints = {
					assignVariableTypes = true,
					compositeLiteralFields = true,
					constantValues = true,
					functionTypeParameters = true,
					parameterNames = true,
					rangeVariableTypes = true,
				},
			},
			pyright = {
				python = {
					analysis = {
						typeCheckingMode = "standard",
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
						autoImportCompletions = true,
						indexing = true,
					},
				},
			},
			rust_analyzer = {
				["rust-analyzer"] = {
					checkOnSave = { command = "clippy" },
					cargo = { allFeatures = true },
					procMacro = { enable = true },
					diagnostics = {
						disabled = { "unresolved-proc-macro" },
						enableExperimental = false,
					},
					assist = { importEnforceGranularity = true },
				},
			},
			bashls = {},
			ts_ls = {
				typescript = {
					updateImportsOnFileMove = { enabled = "always" },
					suggest = {
						includeCompletionsForModuleExports = true,
						autoImports = true,
					},
					preferences = {
						includePackageJsonAutoImports = "auto",
						importModuleSpecifier = "relative",
					},
					inlayHints = {
						includeInlayParameterNameHints = "literals",
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = false,
					},
				},
			},
			lua_ls = {
				Lua = {
					runtime = { version = "LuaJIT" },
					workspace = {
						checkThirdParty = false,
						library = { vim.env.VIMRUNTIME },
						maxPreload = 2000,
						preloadFileSize = 1000,
					},
					completion = { callSnippet = "Replace" },
					diagnostics = {
						globals = { "vim" },
						groupSeverity = { strong = "Warning", strict = "Warning" },
						disable = { "missing-fields", "undefined-doc-name" },
					},
					telemetry = { enable = false },
					hint = { enable = true },
				},
			},
		}

		-- Enhanced capabilities with modern LSP features
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

		-- Add semantic tokens support
		capabilities.textDocument.semanticTokens =
			vim.lsp.protocol.make_client_capabilities().textDocument.semanticTokens

		-- Enhanced completion capabilities
		capabilities.textDocument.completion.completionItem.snippetSupport = true
		capabilities.textDocument.completion.completionItem.resolveSupport = {
			properties = { "documentation", "detail", "additionalTextEdits" },
		}
		capabilities.textDocument.foldingRange = { lineFoldingOnly = true }
		capabilities.textDocument.colorProvider = true

		-- Setup Nix-managed servers
		for server_name, server_config in pairs(nix_servers) do
			require("lspconfig")[server_name].setup({
				capabilities = capabilities,
				on_attach = on_attach,
				settings = server_config,
			})
		end

		-- Setup nil_ls (Nix LSP)
		require("lspconfig").nil_ls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- Setup jsonls (from vscode-langservers-extracted)
		require("lspconfig").jsonls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				json = {
					schemas = require("schemastore").json.schemas(),
					validate = { enable = true },
				},
			},
		})
	end,
}
