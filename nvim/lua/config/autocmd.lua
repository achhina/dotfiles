local M = {}

function M.load_autocmd()
	-- [[ Highlight on yank ]]
	-- See `:help vim.highlight.on_yank()`
	local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
	vim.api.nvim_create_autocmd("TextYankPost", {
		callback = function()
			vim.highlight.on_yank()
		end,
		group = highlight_group,
		pattern = "*",
	})

	-- Exit ephemeral buffers with <ESC>
	local ephemeral_buffers = { "help", "lspinfo", "man", "checkhealth", "qf", "lazy" }
	vim.api.nvim_create_autocmd({ "FileType" }, {
		callback = function()
			vim.keymap.set("n", "<ESC>", ":bd<CR>", { buffer = true, silent = true })
		end,
		pattern = table.concat(ephemeral_buffers, ","),
	})
end

return M
