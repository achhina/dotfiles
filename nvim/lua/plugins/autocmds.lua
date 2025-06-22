-- Enhanced autocmds for workflow automation
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- General workflow automation
local workflow_group = augroup("WorkflowAutomation", { clear = true })

-- Auto-save when focus is lost
autocmd("FocusLost", {
	group = workflow_group,
	pattern = "*",
	command = "silent! wa",
})

-- Auto-save when switching buffers
autocmd({ "BufLeave", "WinLeave" }, {
	group = workflow_group,
	pattern = "*",
	callback = function()
		if vim.bo.modified and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
			vim.cmd("silent! write")
		end
	end,
})

-- Auto-create parent directories when saving
autocmd("BufWritePre", {
	group = workflow_group,
	callback = function(event)
		if event.match:match("^%w%w+://") then
			return
		end
		local file = vim.loop.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
	group = workflow_group,
	pattern = "*",
	callback = function()
		-- Save cursor position
		local save_cursor = vim.fn.getpos(".")
		-- Remove trailing whitespace
		vim.cmd([[%s/\s\+$//e]])
		-- Restore cursor position
		vim.fn.setpos(".", save_cursor)
	end,
})

-- Language-specific automation
local lang_group = augroup("LanguageSpecific", { clear = true })

-- Go: Auto-format and organize imports on save
autocmd("BufWritePre", {
	group = lang_group,
	pattern = "*.go",
	callback = function()
		-- Organize imports
		local params = vim.lsp.util.make_range_params()
		params.context = { only = { "source.organizeImports" } }
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
		-- Format
		vim.lsp.buf.format({ async = false })
	end,
})

-- Python: Auto-organize imports on save
autocmd("BufWritePre", {
	group = lang_group,
	pattern = "*.py",
	callback = function()
		-- Try to organize imports with LSP
		local params = vim.lsp.util.make_range_params()
		params.context = { only = { "source.organizeImports" } }
		vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
	end,
})

-- TypeScript/JavaScript: Auto-organize imports and format
autocmd("BufWritePre", {
	group = lang_group,
	pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
	callback = function()
		-- Organize imports
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

-- Rust: Auto-format on save
autocmd("BufWritePre", {
	group = lang_group,
	pattern = "*.rs",
	callback = function()
		vim.lsp.buf.format({ async = false })
	end,
})

-- JSON: Auto-format on save
autocmd("BufWritePre", {
	group = lang_group,
	pattern = "*.json",
	callback = function()
		-- Try to format with LSP first, then fall back to jq if available
		local success = pcall(vim.lsp.buf.format, { async = false })
		if not success and vim.fn.executable("jq") == 1 then
			vim.cmd("silent %!jq .")
		end
	end,
})

-- Buffer management automation
local buffer_group = augroup("BufferManagement", { clear = true })

-- Auto-close buffers that haven't been used in a while
autocmd("BufEnter", {
	group = buffer_group,
	callback = function()
		-- Clean up old buffers to prevent memory leaks
		local buffers = vim.api.nvim_list_bufs()
		local loaded_buffers = {}
		local current_time = os.time()

		for _, buf in ipairs(buffers) do
			if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "buflisted") then
				table.insert(loaded_buffers, buf)
			end
		end

		-- If more than 25 buffers are loaded, clean up the oldest ones
		if #loaded_buffers > 25 then
			for i = 1, #loaded_buffers - 20 do
				local buf = loaded_buffers[i]
				if vim.api.nvim_buf_get_option(buf, "modified") == false then
					-- Check if buffer hasn't been accessed recently
					local last_used = vim.api.nvim_buf_get_var(buf, "last_used") or 0
					if current_time - last_used > 300 then -- 5 minutes
						pcall(vim.api.nvim_buf_delete, buf, { force = false })
					end
				end
			end
		end

		-- Update last used time for current buffer
		pcall(vim.api.nvim_buf_set_var, 0, "last_used", current_time)
	end,
})

-- Auto-close help, man, and other temporary buffers
autocmd("FileType", {
	group = buffer_group,
	pattern = { "help", "man", "qf", "quickfix", "startuptime" },
	callback = function()
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = 0, silent = true })
	end,
})

-- Development workflow automation
local dev_group = augroup("DevelopmentWorkflow", { clear = true })

-- Auto-reload files when they change on disk
autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
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

-- Performance optimizations
local perf_group = augroup("PerformanceOptimizations", { clear = true })

-- Disable certain features for large files
autocmd("BufReadPre", {
	group = perf_group,
	callback = function()
		local max_filesize = 1024 * 1024 * 2 -- 2MB
		local filename = vim.fn.expand("<afile>")

		if filename == "" then
			return
		end

		local ok, stats = pcall(vim.loop.fs_stat, filename)
		if ok and stats and stats.size > max_filesize then
			vim.notify("Large file detected. Optimizing for performance.", vim.log.levels.INFO)

			-- Disable expensive features
			vim.opt_local.swapfile = false
			vim.opt_local.foldmethod = "manual"
			vim.opt_local.undolevels = -1
			vim.opt_local.undoreload = 0
			vim.opt_local.list = false

			-- Disable treesitter
			vim.schedule(function()
				pcall(vim.treesitter.stop)
			end)

			-- Disable LSP for very large files
			if stats.size > max_filesize * 5 then -- 10MB
				vim.schedule(function()
					vim.diagnostic.disable(0)
				end)
			end
		end
	end,
})

-- Session management automation
local session_group = augroup("SessionManagement", { clear = true })

-- Auto-load session for project directories
autocmd("VimEnter", {
	group = session_group,
	callback = function()
		-- Only auto-load if no arguments were passed
		if vim.fn.argc(-1) == 0 then
			local has_persistence, persistence = pcall(require, "persistence")
			if has_persistence then
				vim.defer_fn(function()
					persistence.load()
				end, 100)
			end
		end
	end,
	nested = true,
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
		local current_ft = vim.api.nvim_buf_get_option(current_buf, "filetype")

		if current_ft ~= "help" and current_ft ~= "man" then
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local buf = vim.api.nvim_win_get_buf(win)
				local ft = vim.api.nvim_buf_get_option(buf, "filetype")
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

-- Easy escape from terminal mode
autocmd("TermOpen", {
	group = term_group,
	pattern = "*",
	callback = function()
		vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { buffer = 0, silent = true })
		vim.keymap.set("t", "<C-h>", "<cmd>wincmd h<cr>", { buffer = 0, silent = true })
		vim.keymap.set("t", "<C-j>", "<cmd>wincmd j<cr>", { buffer = 0, silent = true })
		vim.keymap.set("t", "<C-k>", "<cmd>wincmd k<cr>", { buffer = 0, silent = true })
		vim.keymap.set("t", "<C-l>", "<cmd>wincmd l<cr>", { buffer = 0, silent = true })
	end,
})

return {}
