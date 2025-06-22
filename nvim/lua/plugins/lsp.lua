return {
	-- LSP Configuration & Plugins
	"neovim/nvim-lspconfig",
	dependencies = {
		-- Automatically install LSPs to stdpath for neovim
		{ "williamboman/mason.nvim", config = true },
		"williamboman/mason-lspconfig.nvim",

		-- Useful status updates for LSP
		-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
		{ "j-hui/fidget.nvim", opts = {} },
	},
	config = function()
		-- [[ Configure LSP ]]
		--  This function gets run when an LSP connects to a particular buffer.
		local on_attach = function(_, bufnr)
			require("config.keymaps").load_lsp_keymaps(bufnr)
		end

		-- Mason-managed servers (keeping TypeScript and Lua for now)
		local mason_servers = {
			ts_ls = {
				typescript = {
					inlayHints = {
						includeInlayParameterNameHints = "all",
						includeInlayParameterNameHintsWhenArgumentMatchesName = false,
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = true,
					},
				},
			},
			lua_ls = {
				Lua = {
					runtime = {
						version = "LuaJIT",
					},
					workspace = {
						checkThirdParty = false,
						library = {
							vim.env.VIMRUNTIME,
							"${3rd}/luv/library",
						},
						maxPreload = 100000,
						preloadFileSize = 10000,
					},
					telemetry = { enable = false },
					diagnostics = {
						globals = { "vim" },
						disable = { "missing-fields", "undefined-doc-name" },
					},
					format = {
						enable = true,
						defaultConfig = {
							indent_style = "space",
							indent_size = "2",
							quote_style = "double",
						},
					},
					hint = {
						enable = true,
						arrayIndex = "Disable", -- "Enable" | "Auto" | "Disable"
						await = true,
						paramName = "Disable", -- "All" | "Literal" | "Disable"
						paramType = true,
						semicolon = "Disable", -- "All" | "SameLine" | "Disable"
						setType = false,
					},
				},
			},
		}

		-- Nix-managed server configurations
		local nix_servers = {
			clangd = {},
			gopls = {},
			pyright = {
				python = {
					analysis = {
						typeCheckingMode = "basic",
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
					},
				},
			},
			rust_analyzer = {
				["rust-analyzer"] = {
					checkOnSave = {
						command = "clippy",
					},
				},
			},
			bashls = {},
		}

		-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

		-- Setup Mason and mason-lspconfig
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = vim.tbl_keys(mason_servers),
			automatic_installation = false, -- Disable to prevent unwanted auto-installs
		})

		-- Setup Mason-managed servers
		for server_name, server_config in pairs(mason_servers) do
			require("lspconfig")[server_name].setup({
				capabilities = capabilities,
				on_attach = on_attach,
				settings = server_config,
			})
		end

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
