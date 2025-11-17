local M = {}

function M.load_options()
	vim.o.hlsearch = false
	vim.wo.number = true
	vim.o.mouse = "a"

	-- Remove this option if you want your OS clipboard to remain independent.
	vim.o.clipboard = "unnamedplus"

	vim.o.breakindent = true
	vim.o.undofile = true

	-- Case insensitive searching UNLESS /C or capital in search
	vim.o.ignorecase = true
	vim.o.smartcase = true

	vim.wo.signcolumn = "yes"

	vim.o.updatetime = 250
	vim.o.timeout = true
	vim.o.timeoutlen = 300

	vim.o.autoread = true

	-- Enhanced command-line completion (handled by noice.nvim)
	vim.o.wildmenu = true
	vim.o.wildmode = "full"
	vim.o.wildoptions = "pum,tagfile"

	-- NOTE: You should make sure your terminal supports this
	vim.o.termguicolors = true

	-- Neovim 0.10+ supports OSC8 hyperlinks automatically when termguicolors is enabled

	vim.opt.tabstop = 4
	vim.opt.shiftwidth = 4
	vim.opt.expandtab = true

	vim.opt.spelllang = "en_us"
	vim.wo.relativenumber = true
	vim.wo.scrolloff = 999
	vim.opt.colorcolumn = "80,88,120"

	vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
end

return M
