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
					-- Enhanced format with potential git blame info
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
			config = config or {}
			config.border = "rounded"

			if result and result.contents then
				-- Could add git blame or other contextual info here
				local bufnr = ctx.bufnr
				local line = vim.api.nvim_win_get_cursor(0)[1] - 1

				-- Add git blame info if available
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
						-- Add git info to hover (simplified)
						if type(result.contents) == "table" and result.contents.value then
							result.contents.value = result.contents.value .. "\n\n---\n*Git: " .. blame_info .. "*"
						end
					end
				end
			end

			return original_hover(err, result, ctx, config)
		end

		-- Performance optimizations
		vim.lsp.set_log_level("WARN")
		vim.opt.updatetime = 250

		-- Memory management
		vim.g.lsp_zero_extend_cmp = 0

		-- LSP Health Monitoring
		local function setup_lsp_monitoring()
			-- Track server restarts and crashes
			vim.api.nvim_create_autocmd("LspDetach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client then
						vim.notify("LSP server disconnected: " .. client.name, vim.log.levels.WARN)
						-- Auto-restart logic only for lspconfig-managed servers
						vim.defer_fn(function()
							-- Skip auto-restart for non-lspconfig servers like copilot
							if client.name == "copilot" then
								return -- Copilot manages its own lifecycle
							end

							local bufnr = vim.api.nvim_get_current_buf()
							local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
							if filetype and filetype ~= "" then
								vim.cmd("LspRestart")
							end
						end, 2000)
					end
				end,
			})

			-- Monitor LSP performance
			vim.api.nvim_create_autocmd("LspRequest", {
				callback = function(args)
					if vim.g.lsp_performance_tracking and args.data.client_name then
						local tracking = vim.g.lsp_performance_tracking[args.data.client_name]
						if tracking then
							tracking.requests = (tracking.requests or 0) + 1
						end
					end
				end,
			})
		end
		setup_lsp_monitoring()

		-- Advanced LSP metrics and status
		_G.lsp_status = function()
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients == 0 then
				return "No LSP"
			end

			local names = {}
			for _, client in ipairs(clients) do
				local status = "●"
				local perf_info = ""

				-- Check performance metrics
				if vim.g.lsp_performance_tracking and vim.g.lsp_performance_tracking[client.name] then
					local tracking = vim.g.lsp_performance_tracking[client.name]
					local elapsed = (vim.loop.hrtime() - tracking.start_time) / 1e9
					local rps = tracking.requests / math.max(elapsed, 1) -- requests per second

					if rps > 10 then
						status = "⚡" -- High activity
					elseif client.is_stopped() then
						status = "●" -- Stopped
					else
						status = "●" -- Normal
					end

					if elapsed > 300 then -- 5 minutes
						perf_info = string.format("(%d req, %.0fs)", tracking.requests, elapsed)
					end
				end

				table.insert(names, status .. client.name .. perf_info)
			end
			return " " .. table.concat(names, " ")
		end

		-- Advanced diagnostic filtering and metrics
		local function setup_diagnostic_metrics()
			-- Track diagnostic counts
			vim.g.diagnostic_metrics = {
				errors = 0,
				warnings = 0,
				info = 0,
				hints = 0,
			}

			-- Update metrics when diagnostics change
			vim.api.nvim_create_autocmd("DiagnosticChanged", {
				callback = function()
					local diagnostics = vim.diagnostic.get(0)
					local counts = { errors = 0, warnings = 0, info = 0, hints = 0 }

					for _, diag in ipairs(diagnostics) do
						if diag.severity == vim.diagnostic.severity.ERROR then
							counts.errors = counts.errors + 1
						elseif diag.severity == vim.diagnostic.severity.WARN then
							counts.warnings = counts.warnings + 1
						elseif diag.severity == vim.diagnostic.severity.INFO then
							counts.info = counts.info + 1
						elseif diag.severity == vim.diagnostic.severity.HINT then
							counts.hints = counts.hints + 1
						end
					end

					vim.g.diagnostic_metrics = counts
				end,
			})

			-- Smart diagnostic filtering based on file type and context
			local original_handler = vim.diagnostic.handlers.virtual_text
			vim.diagnostic.handlers.virtual_text = {
				show = function(namespace, bufnr, diagnostics, opts)
					-- Filter diagnostics based on context
					local filtered = vim.tbl_filter(function(diagnostic)
						-- Hide certain diagnostics in large files
						local line_count = vim.api.nvim_buf_line_count(bufnr)
						if line_count > 1000 and diagnostic.severity > vim.diagnostic.severity.WARN then
							return false
						end

						-- Hide noisy TypeScript diagnostics in certain contexts
						if diagnostic.source == "typescript" then
							if diagnostic.code == 2339 and diagnostic.message:match("Property .* does not exist") then
								-- Could be a false positive in dynamic code
								local line =
									vim.api.nvim_buf_get_lines(bufnr, diagnostic.lnum, diagnostic.lnum + 1, false)[1]
								if line and line:match("%.%w+%s*=") then -- Assignment to property
									return false
								end
							end
						end

						return true
					end, diagnostics)

					return original_handler.show(namespace, bufnr, filtered, opts)
				end,
				hide = original_handler.hide,
			}
		end
		setup_diagnostic_metrics()

		-- Global function to get diagnostic summary
		_G.diagnostic_summary = function()
			if vim.g.diagnostic_metrics then
				local m = vim.g.diagnostic_metrics
				local total = m.errors + m.warnings + m.info + m.hints
				if total == 0 then
					return "✓"
				end

				local parts = {}
				if m.errors > 0 then
					table.insert(parts, "E:" .. m.errors)
				end
				if m.warnings > 0 then
					table.insert(parts, "W:" .. m.warnings)
				end
				if m.info > 0 then
					table.insert(parts, "I:" .. m.info)
				end
				if m.hints > 0 then
					table.insert(parts, "H:" .. m.hints)
				end

				return table.concat(parts, " ")
			end
			return ""
		end

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

			-- Code lens support
			if client.supports_method("textDocument/codeLens") then
				vim.lsp.codelens.refresh()
				vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
					buffer = bufnr,
					group = vim.api.nvim_create_augroup("LSPCodeLens", { clear = false }),
					callback = function()
						vim.lsp.codelens.refresh()
					end,
				})
			end

			-- Performance tracking for this client
			if not vim.g.lsp_performance_tracking then
				vim.g.lsp_performance_tracking = {}
			end
			vim.g.lsp_performance_tracking[client.name] = {
				start_time = vim.loop.hrtime(),
				requests = 0,
			}

			-- Resource management and limits
			local function setup_client_limits(lsp_client)
				if lsp_client.name == "ts_ls" then
					-- TypeScript memory management
					if lsp_client.config.init_options then
						lsp_client.config.init_options.maxTsServerMemory = 4096
					end
				elseif lsp_client.name == "rust_analyzer" then
					-- Rust analyzer can be CPU intensive
					if lsp_client.config.settings and lsp_client.config.settings["rust-analyzer"] then
						lsp_client.config.settings["rust-analyzer"].cargo = lsp_client.config.settings["rust-analyzer"].cargo
							or {}
						lsp_client.config.settings["rust-analyzer"].cargo.target = nil -- Don't specify target for performance
					end
				end
			end
			setup_client_limits(client)

			-- Auto-cleanup for unused servers (lightweight implementation)
			vim.defer_fn(function()
				local active_buffers = vim.tbl_filter(function(buf)
					return vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "buflisted")
				end, vim.api.nvim_list_bufs())

				if #active_buffers == 0 then
					-- No active buffers, could cleanup resources
					if vim.g.lsp_performance_tracking and vim.g.lsp_performance_tracking[client.name] then
						local elapsed = (vim.loop.hrtime() - vim.g.lsp_performance_tracking[client.name].start_time)
							/ 1e9
						if elapsed > 3600 then -- 1 hour of inactivity
							vim.notify("Consider restarting LSP server: " .. client.name, vim.log.levels.INFO)
						end
					end
				end
			end, 60000) -- Check every minute

			-- Attach navic for breadcrumbs if available
			if client.server_capabilities.documentSymbolProvider then
				local navic_ok, navic = pcall(require, "nvim-navic")
				if navic_ok then
					navic.attach(client, bufnr)
				end
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
					pythonPath = function()
						-- Auto-detect virtual environment
						local venv_path = os.getenv("VIRTUAL_ENV")
						if venv_path then
							return venv_path .. "/bin/python"
						end
						return vim.fn.exepath("python3") or vim.fn.exepath("python")
					end,
					analysis = {
						typeCheckingMode = "standard",
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
						autoImportCompletions = true,
						indexing = true,
						extraPaths = { "." },
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
			ts_ls = {
				init_options = {
					maxTsServerMemory = 4096,
				},
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
					workspaceSymbols = { scope = "allOpenProjects" },
				},
				javascript = {
					updateImportsOnFileMove = { enabled = "always" },
					suggest = { autoImports = true },
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

		-- Setup Nix-managed servers with error handling
		local function safe_setup_server(name, config)
			local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
			if not lspconfig_ok then
				vim.notify("LSPConfig not available", vim.log.levels.ERROR)
				return false
			end

			local server_setup_ok, server_setup_err = pcall(function()
				lspconfig[name].setup({
					capabilities = capabilities,
					on_attach = on_attach,
					settings = config,
				})
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

		-- Setup nil_ls (Nix LSP)
		safe_setup_server("nil_ls", {})

		-- Setup jsonls (from vscode-langservers-extracted)
		local jsonls_setup_ok, jsonls_setup_err = pcall(function()
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
		end)

		if not jsonls_setup_ok then
			vim.notify("Failed to setup jsonls: " .. jsonls_setup_err, vim.log.levels.WARN)
		end
	end,
}
