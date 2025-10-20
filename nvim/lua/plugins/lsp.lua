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

		-- Enhanced diagnostics with Git integration
		vim.diagnostic.config({
			virtual_text = {
				severity = { min = vim.diagnostic.severity.WARN },
				source = "if_many",
				format = function(diagnostic)
					return string.format("%s (%s)", diagnostic.message, diagnostic.source)
				end,
			},
			float = {
				border = "rounded",
				source = "always",
				format = function(diagnostic)
					local message = diagnostic.message
					if diagnostic.source then
						message = string.format("[%s] %s", diagnostic.source, message)
					end
					return message
				end,
			},
			signs = true,
			underline = true,
			update_in_insert = false,
			severity_sort = true,
		})

		-- Enhanced hover with git integration
		local original_hover = vim.lsp.handlers["textDocument/hover"]
		vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
			if result and result.contents then
				-- Could add git blame or other contextual info here
				local bufnr = ctx.bufnr
				local line = vim.api.nvim_win_get_cursor(0)[1] - 1

				local git_blame = vim.fn.system(
					string.format(
						"git blame -L %d,%d %s 2>/dev/null",
						line + 1,
						line + 1,
						vim.api.nvim_buf_get_name(bufnr)
					)
				)

				if vim.v.shell_error == 0 and git_blame and git_blame ~= "" then
					local blame_info = git_blame:match("%((.-)%)")
					if blame_info then
						if type(result.contents) == "table" and result.contents.value then
							result.contents.value = result.contents.value .. "\n\n---\n*Git: " .. blame_info .. "*"
						end
					end
				end
			end

			return original_hover(err, result, ctx, config)
		end

		vim.opt.updatetime = 250

		--  This function gets run when an LSP connects to a particular buffer.
		local on_attach = function(client, bufnr)
			require("config.keymaps").load_lsp_keymaps(bufnr)

			if client:supports_method("textDocument/inlayHint") then
				vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			end

			-- Document highlighting
			if client:supports_method("textDocument/documentHighlight") then
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

			-- Code lens support
			if client:supports_method("textDocument/codeLens") then
				vim.lsp.codelens.refresh()
				vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
					buffer = bufnr,
					group = vim.api.nvim_create_augroup("LSPCodeLens", { clear = false }),
					callback = function()
						vim.lsp.codelens.refresh()
					end,
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
			basedpyright = {
				python = {
					pythonPath = (function()
						-- 1. Check VIRTUAL_ENV environment variable
						local venv_path = os.getenv("VIRTUAL_ENV")
						if venv_path then
							return venv_path .. "/bin/python3"
						end

						-- 2. Check for .venv in current working directory
						local cwd = vim.fn.getcwd()
						local local_venv = cwd .. "/.venv/bin/python3"
						if vim.fn.executable(local_venv) == 1 then
							return local_venv
						end

						-- 3. Fall back to system Python
						return vim.fn.exepath("python3") or vim.fn.exepath("python")
					end)(),
				},
				analysis = {
					-- Type checking mode: "off", "basic", "standard", "recommended", "strict", "all"
					typeCheckingMode = "recommended",

					-- Diagnostics
					diagnosticMode = "workspace", -- Analyze all files in workspace

					-- Search and import
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
					autoImportCompletions = true,
					extraPaths = { "." },

					-- Basedpyright-specific features
					indexing = true,
					autoFormatStrings = true,

					-- Inlay hints
					inlayHints = {
						variableTypes = true,
						callArgumentNames = true,
						functionReturnTypes = true,
						genericTypes = false,
					},

					-- Diagnostic overrides
					diagnosticSeverityOverrides = {
						reportMissingTypeStubs = "none",
					},
				},
			},
			rust_analyzer = {
				["rust-analyzer"] = {
					checkOnSave = { command = "clippy" },
					cargo = {
						allFeatures = true,
						loadOutDirsFromCheck = true,
					},
					procMacro = {
						enable = true,
						attributes = { enable = true },
					},
					diagnostics = {
						disabled = { "unresolved-proc-macro" },
						experimental = { enable = true },
					},
					assist = { importEnforceGranularity = true },
					completion = {
						addCallArgumentSnippets = true,
						addCallParenthesis = true,
					},
				},
			},
			bashls = {},
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
			nil_ls = {},
			jsonls = {
				json = {
					schemas = require("schemastore").json.schemas(),
					validate = { enable = true },
				},
			},
		}

		-- Enhanced capabilities with modern LSP features
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

		capabilities.textDocument.semanticTokens =
			vim.lsp.protocol.make_client_capabilities().textDocument.semanticTokens

		-- Enhanced completion capabilities
		capabilities.textDocument.completion.completionItem.snippetSupport = true
		capabilities.textDocument.completion.completionItem.resolveSupport = {
			properties = { "documentation", "detail", "additionalTextEdits" },
		}
		capabilities.textDocument.foldingRange = {
			dynamicRegistration = false,
			lineFoldingOnly = true,
		}
		capabilities.textDocument.colorProvider = {
			dynamicRegistration = false,
		}

		-- Setup Nix-managed servers with error handling
		local function safe_setup_server(name, config)
			local server_setup_ok, server_setup_err = pcall(function()
				vim.lsp.config[name] = {
					capabilities = capabilities,
					on_attach = on_attach,
					settings = config,
				}
				vim.lsp.enable(name)
			end)

			if not server_setup_ok then
				vim.notify("Failed to setup LSP server " .. name .. ": " .. server_setup_err, vim.log.levels.WARN)
				return false
			end

			return true
		end

		for server_name, server_config in pairs(nix_servers) do
			safe_setup_server(server_name, server_config)
		end
	end,
}
