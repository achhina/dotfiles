return {
	"neovim/nvim-lspconfig",
	dependencies = {
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
		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers["textDocument/hover"], {
			border = "rounded",
			max_width = 80,
			max_height = 20,
		})

		vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers["textDocument/signatureHelp"], {
			border = "rounded",
			silent = true,
		})

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

		vim.opt.updatetime = 250
		vim.lsp.inlay_hint.enable(true)

		local on_attach = function(_, bufnr)
			require("config.keymaps").load_lsp_keymaps(bufnr)
		end

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
						local venv_path = os.getenv("VIRTUAL_ENV")
						if venv_path then
							return venv_path .. "/bin/python3"
						end

						local cwd = vim.fn.getcwd()
						local local_venv = cwd .. "/.venv/bin/python3"
						if vim.fn.executable(local_venv) == 1 then
							return local_venv
						end

						return vim.fn.exepath("python3") or vim.fn.exepath("python")
					end)(),
				},
				analysis = {
					typeCheckingMode = "recommended",
					diagnosticMode = "workspace",
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
					autoImportCompletions = true,
					extraPaths = { "." },
					indexing = true,
					autoFormatStrings = true,

					inlayHints = {
						variableTypes = true,
						callArgumentNames = true,
						functionReturnTypes = true,
						genericTypes = false,
					},

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

		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

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
