return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			-- Customize or remove this keymap to your liking
			"<leader>F",
			function()
				require("conform").format({ async = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	-- This will provide type hinting with LuaLS
	---@module "conform"
	---@type conform.setupOpts
	opts = {
		-- Define your formatters
		formatters_by_ft = {
			lua = { "StyLua" },
			python = function(bufnr)
				if require("conform").get_formatter_info("ruff_format", bufnr).available then
					return {
						"ruff_format",
						"ruff_fix",
						"ruff_organize_imports",
					}
				else
					return { "isort", "black" }
				end
			end,
			rust = {
				"rustfmt",
			},
			html = {
				"prettier",
			},
			css = {
				"prettier",
			},
			javascript = {
				"prettier",
			},
			typescript = {
				"prettier",
			},
			javascriptreact = {
				"prettier",
			},
			typescriptreact = {
				"prettier",
			},
		},
		-- Set default options
		default_format_opts = {
			lsp_format = "fallback",
			format_on_save = false,
			format_after_save = false,
		},
	},
	init = function()
		-- If you want the formatexpr, here is the place to set it
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
