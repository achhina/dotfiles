return {
	"stevearc/conform.nvim",
	opts = {
		lsp_fallback = true,
		formatters_by_ft = {
			lua = { "stylua", lsp_fallback = true },
			python = { "ruff_format", "ruff_fix", "ruff_organize_imports" },
			rust = { "rustfmt" },
			html = { "prettier" },
			css = { "prettier" },
			js = { "prettier" },
			jsx = { "prettier" },
		},
		notify_on_error = true,
	},
}
