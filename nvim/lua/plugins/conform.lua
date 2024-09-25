return {
	"stevearc/conform.nvim",
	opts = {
		lsp_fallback = true,
		formatters_by_ft = {
			lua = {
				"stylua",
				format_on_save = nil,
				format_after_save = nil,
			},
			python = {
				"ruff_format",
				"ruff_fix",
				"ruff_organize_imports",
				format_on_save = nil,
				format_after_save = nil,
			},
			rust = {
				"rustfmt",
				format_on_save = nil,
				format_after_save = nil,
			},
			html = {
				"prettier",
				format_on_save = nil,
				format_after_save = nil,
			},
			css = {
				"prettier",
				format_on_save = nil,
				format_after_save = nil,
			},
			js = {
				"prettier",
				format_on_save = nil,
				format_after_save = nil,
			},
			jsx = {
				"prettier",
				format_on_save = nil,
				format_after_save = nil,
			},
		},
		notify_on_error = true,
		format_on_save = nil,
		format_after_save = nil,
	},
}
