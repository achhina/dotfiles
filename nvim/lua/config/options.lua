local M = {}

function M.load_options()
	-- Set highlight on search
	vim.o.hlsearch = false

	-- Make line numbers default
	vim.wo.number = true

	-- Enable mouse mode
	vim.o.mouse = "a"

	-- Sync clipboard between OS and Neovim.
	--  Remove this option if you want your OS clipboard to remain independent.
	--  See `:help 'clipboard'`
	vim.o.clipboard = "unnamedplus"

	-- Enable break indent
	vim.o.breakindent = true

	-- Save undo history
	vim.o.undofile = true

	-- Case insensitive searching UNLESS /C or capital in search
	vim.o.ignorecase = true
	vim.o.smartcase = true

	-- Keep signcolumn on by default
	vim.wo.signcolumn = "yes"

	-- Decrease update time
	vim.o.updatetime = 250
	vim.o.timeout = true
	vim.o.timeoutlen = 300

	-- Enhanced command-line completion (handled by noice.nvim)
	vim.o.wildmenu = true
	vim.o.wildmode = "full"
	vim.o.wildoptions = "pum,tagfile"

	-- NOTE: You should make sure your terminal supports this
	vim.o.termguicolors = true

	-- Set default tab to 4 instead of 8
	vim.opt.tabstop = 4
	vim.opt.shiftwidth = 4
	vim.opt.expandtab = true

	-- Enable spellcheck
	vim.opt.spelllang = "en_us"

	-- Relative line numbers
	vim.wo.relativenumber = true

	-- Keep text centred vertically
	vim.wo.scrolloff = 999

	-- Set vertical rulers
	vim.opt.colorcolumn = "80,88,120"

	-- What things to save for vim sessions
	vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
end

return M
