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

	-- Go to last edit position when opening file
	vim.api.nvim_create_autocmd("BufReadPost", {
		callback = function()
			local mark = vim.api.nvim_buf_get_mark(0, '"')
			if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) then
				vim.api.nvim_win_set_cursor(0, mark)
			end
		end,
	})
end

return M
