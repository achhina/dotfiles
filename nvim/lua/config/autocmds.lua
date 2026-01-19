local M = {}

function M.load_autocmds()
	local autocmd = vim.api.nvim_create_autocmd
	local augroup = vim.api.nvim_create_augroup

	local workflow_group = augroup("WorkflowAutomation", { clear = true })

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

	local buffer_group = augroup("BufferManagement", { clear = true })

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

	local dev_group = augroup("DevelopmentWorkflow", { clear = true })

	autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermLeave", "TermClose" }, {
		group = dev_group,
		pattern = "*",
		command = "if mode() != 'c' | checktime | endif",
	})

	local function checktime_safe()
		if vim.fn.mode() ~= "c" then
			vim.cmd("checktime")
		end
	end

	vim.fn.timer_start(1000, checktime_safe, { ["repeat"] = -1 })

	autocmd("FileChangedShellPost", {
		group = dev_group,
		pattern = "*",
		callback = function()
			vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.WARN)
		end,
	})

	autocmd("BufWritePost", {
		group = dev_group,
		pattern = "*.tex",
		callback = function()
			if vim.fn.executable("pdflatex") == 1 then
				vim.cmd("silent !pdflatex % &")
			end
		end,
	})

	local git_group = augroup("GitWorkflow", { clear = true })

	autocmd({ "BufEnter", "FocusGained" }, {
		group = git_group,
		pattern = { "*.git/*", ".gitignore", ".gitmodules" },
		callback = function()
			if package.loaded["gitsigns"] then
				require("gitsigns").refresh()
			end
		end,
	})

	local ui_group = augroup("UIImprovements", { clear = true })

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

	autocmd("VimResized", {
		group = ui_group,
		callback = function()
			-- Save current tab before tabdo
			local current_tab = vim.api.nvim_get_current_tabpage()

			-- Equalize all windows first
			vim.cmd("tabdo wincmd =")

			-- Restore current tab
			vim.api.nvim_set_current_tabpage(current_tab)

			-- Then resize Claude Code terminal to maintain its configured width percentage
			local ok, claudecode = pcall(require, "claudecode")
			if ok then
				local config = claudecode.config or {}
				local terminal_config = config.terminal or {}
				local width_pct = terminal_config.split_width_percentage or 0.40

				-- Get the Claude Code terminal buffer number
				local term_ok, term_module = pcall(require, "claudecode.terminal")
				if term_ok and term_module.get_active_terminal_bufnr then
					local claude_bufnr = term_module.get_active_terminal_bufnr()

					-- Find window displaying the Claude Code terminal
					if claude_bufnr then
						for _, win in ipairs(vim.api.nvim_list_wins()) do
							local buf = vim.api.nvim_win_get_buf(win)
							if buf == claude_bufnr then
								-- Calculate desired width based on total columns
								local desired_width = math.floor(vim.o.columns * width_pct)
								pcall(vim.api.nvim_win_set_width, win, desired_width)
								break -- Found the window, stop searching
							end
						end
					end
				end
			end
		end,
	})

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

	autocmd("BufEnter", {
		group = ui_group,
		callback = function()
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

	local term_group = augroup("TerminalAutomation", { clear = true })

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
