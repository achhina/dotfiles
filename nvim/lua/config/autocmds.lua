local M = {}

function M.load_autocmds()
	local autocmd = vim.api.nvim_create_autocmd
	local augroup = vim.api.nvim_create_augroup

	-- General workflow automation
	local workflow_group = augroup("WorkflowAutomation", { clear = true })

	-- Auto-create parent directories when saving
	autocmd("BufWritePre", {
		group = workflow_group,
		callback = function(event)
			if event.match:match("^%w%w+://") then
				return
			end
			local file = vim.uv.fs_realpath(event.match) or event.match
			vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
		end,
	})

	-- Buffer management automation
	local buffer_group = augroup("BufferManagement", { clear = true })

	-- Exit ephemeral buffers with ESC
	autocmd("FileType", {
		group = buffer_group,
		pattern = {
			"help",
			"lspinfo",
			"man",
			"checkhealth",
			"qf",
			"quickfix",
			"lazy",
			"startuptime",
			"fugitive",
			"fugitiveblame",
			"git",
		},
		callback = function()
			vim.keymap.set("n", "<ESC>", "<cmd>close<cr>", { buffer = 0, silent = true })
			vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = 0, silent = true })
		end,
	})

	-- Development workflow automation
	local dev_group = augroup("DevelopmentWorkflow", { clear = true })

	-- Auto-reload files when they change on disk
	autocmd({ "FocusGained", "CursorHold" }, {
		group = dev_group,
		pattern = "*",
		command = "if mode() != 'c' | checktime | endif",
	})

	-- Notification when file changes on disk
	autocmd("FileChangedShellPost", {
		group = dev_group,
		pattern = "*",
		callback = function()
			vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.WARN)
		end,
	})

	-- Auto-compile on save for certain filetypes
	autocmd("BufWritePost", {
		group = dev_group,
		pattern = "*.tex",
		callback = function()
			if vim.fn.executable("pdflatex") == 1 then
				vim.cmd("silent !pdflatex % &")
			end
		end,
	})

	-- Git workflow automation
	local git_group = augroup("GitWorkflow", { clear = true })

	-- Auto-reload git status when entering git-related files
	autocmd({ "BufEnter", "FocusGained" }, {
		group = git_group,
		pattern = { "*.git/*", ".gitignore", ".gitmodules" },
		callback = function()
			-- Refresh git signs
			if package.loaded["gitsigns"] then
				require("gitsigns").refresh()
			end
		end,
	})

	-- UI/UX improvements
	local ui_group = augroup("UIImprovements", { clear = true })

	-- Highlight yanked text
	autocmd("TextYankPost", {
		group = ui_group,
		pattern = "*",
		callback = function()
			vim.hl.on_yank({
				higroup = "IncSearch",
				timeout = 300,
			})
		end,
	})

	-- Auto-resize splits when window is resized
	autocmd("VimResized", {
		group = ui_group,
		callback = function()
			vim.cmd("tabdo wincmd =")
		end,
	})

	-- Remember last position in file
	autocmd("BufReadPost", {
		group = ui_group,
		callback = function()
			local exclude = { "gitcommit" }
			local buf = vim.api.nvim_get_current_buf()
			if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_pos then
				return
			end
			vim.b[buf].last_pos = true
			local mark = vim.api.nvim_buf_get_mark(buf, '"')
			local lcount = vim.api.nvim_buf_line_count(buf)
			if mark[1] > 0 and mark[1] <= lcount then
				pcall(vim.api.nvim_win_set_cursor, 0, mark)
			end
		end,
	})

	-- Auto-close unnecessary windows
	autocmd("BufEnter", {
		group = ui_group,
		callback = function()
			-- Close help windows when entering normal buffers
			local current_buf = vim.api.nvim_get_current_buf()
			local current_ft = vim.bo[current_buf].filetype

			if current_ft ~= "help" and current_ft ~= "man" then
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					local buf = vim.api.nvim_win_get_buf(win)
					local ft = vim.bo[buf].filetype
					if ft == "help" or ft == "man" then
						pcall(vim.api.nvim_win_close, win, false)
					end
				end
			end
		end,
	})

	-- Terminal automation
	local term_group = augroup("TerminalAutomation", { clear = true })

	-- Start in insert mode when entering terminal
	autocmd("TermOpen", {
		group = term_group,
		pattern = "*",
		callback = function()
			vim.opt_local.number = false
			vim.opt_local.relativenumber = false
			vim.opt_local.signcolumn = "no"
			vim.cmd("startinsert")
		end,
	})
end

return M
