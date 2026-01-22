-- NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Start MCP socket server for Claude Code integration
-- Let Neovim create the socket in its standard temp location
local mcp_socket = vim.fn.serverstart()
-- Set environment variable so claudecode.nvim can pass it to Claude Code
vim.env.NVIM_MCP_SOCKET = mcp_socket

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {})
require("config")
