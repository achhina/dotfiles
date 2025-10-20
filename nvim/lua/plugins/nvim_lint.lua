return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		-- Configure linters by filetype (only if available)
		lint.linters_by_ft = {
			python = { "ruff" },
			javascript = { "eslint_d" },
			typescript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescriptreact = { "eslint_d" },
			go = { "golangcilint" },
			sh = { "shellcheck" },
			bash = { "shellcheck" },
			dockerfile = { "hadolint" },
			yaml = { "yamllint" },
			-- markdown = { "markdownlint" }, -- Disabled until markdownlint is installed
		}

		-- Auto-lint on save and text change
		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave", "TextChanged" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})

		-- Manual lint keymap
		vim.keymap.set("n", "<leader>cl", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}
