local M = {}

-- Safe keymap helper that validates functions before setting
local function safe_keymap(mode, lhs, rhs, opts, bufnr)
	opts = opts or {}

	-- Validate rhs - only reject if it's clearly invalid
	if rhs == nil then
		vim.notify("Skipping invalid keymap: " .. lhs .. " -> nil", vim.log.levels.WARN)
		return false
	end

	-- Functions are always valid
	if type(rhs) == "function" then
		-- Set buffer-specific or global keymap
		if bufnr then
			opts.buffer = bufnr
		end
		vim.keymap.set(mode, lhs, rhs, opts)
		return true
	end

	-- Strings are typically valid (vim sequences, commands, etc.)
	if type(rhs) == "string" then
		-- Set buffer-specific or global keymap
		if bufnr then
			opts.buffer = bufnr
		end
		vim.keymap.set(mode, lhs, rhs, opts)
		return true
	end

	-- Other types are likely invalid
	vim.notify(
		"Skipping invalid keymap: " .. lhs .. " -> " .. tostring(rhs) .. " (type: " .. type(rhs) .. ")",
		vim.log.levels.WARN
	)
	return false
end

-- Enhanced LSP keymap creator with validation
local function create_lsp_keymap(bufnr)
	-- Helper functions for different modes
	local function nmap(keys, func, desc)
		local full_desc = desc and ("LSP: " .. desc) or nil
		return safe_keymap("n", keys, func, { desc = full_desc }, bufnr)
	end

	local function vmap(keys, func, desc)
		local full_desc = desc and ("LSP: " .. desc) or nil
		return safe_keymap("v", keys, func, { desc = full_desc }, bufnr)
	end

	local function imap(keys, func, desc)
		local full_desc = desc and ("LSP: " .. desc) or nil
		return safe_keymap("i", keys, func, { desc = full_desc }, bufnr)
	end

	-- Check telescope availability for LSP functions
	local has_telescope, telescope_builtin = pcall(require, "telescope.builtin")

	-- Core LSP navigation with telescope fallbacks
	nmap("gd", vim.lsp.buf.definition, "Goto Definition")
	nmap("gI", vim.lsp.buf.implementation, "Goto Implementation")
	nmap("<leader>D", vim.lsp.buf.type_definition, "Type Definition")

	-- References with telescope or fallback
	if has_telescope and telescope_builtin.lsp_references then
		nmap("gr", telescope_builtin.lsp_references, "Goto References")
	else
		nmap("gr", vim.lsp.buf.references, "Goto References")
	end

	-- Document symbols with telescope or fallback
	if has_telescope and telescope_builtin.lsp_document_symbols then
		nmap("<leader>sy", telescope_builtin.lsp_document_symbols, "Document Symbols")
	else
		nmap("<leader>sy", vim.lsp.buf.document_symbol, "Document Symbols")
	end

	-- Workspace symbols with telescope or fallback
	if has_telescope and telescope_builtin.lsp_dynamic_workspace_symbols then
		nmap("<leader>ws", telescope_builtin.lsp_dynamic_workspace_symbols, "Workspace Symbols")
	else
		nmap("<leader>ws", vim.lsp.buf.workspace_symbol, "Workspace Symbols")
	end

	-- Core LSP actions
	nmap("K", vim.lsp.buf.hover, "Hover Documentation")
	nmap("<leader>k", vim.lsp.buf.signature_help, "Signature Documentation")
	nmap("<leader>ca", vim.lsp.buf.code_action, "Code Action")
	nmap("<leader>F", vim.lsp.buf.format, "Format Document")

	-- Rename with input validation
	nmap("<leader>rn", function()
		local new_name = vim.fn.input("New name: ", vim.fn.expand("<cword>"))
		if new_name ~= "" and new_name ~= vim.fn.expand("<cword>") then
			vim.lsp.buf.rename(new_name)
		end
	end, "Rename with preview")

	-- Advanced LSP features (check if they exist)
	if vim.lsp.buf.incoming_calls then
		nmap("<leader>ci", vim.lsp.buf.incoming_calls, "Incoming calls")
	end
	if vim.lsp.buf.outgoing_calls then
		nmap("<leader>co", vim.lsp.buf.outgoing_calls, "Outgoing calls")
	end
	if vim.lsp.buf.type_hierarchy then
		nmap("<leader>th", vim.lsp.buf.type_hierarchy, "Type Hierarchy")
	end
	if vim.lsp.codelens and vim.lsp.codelens.run then
		nmap("<leader>cl", vim.lsp.codelens.run, "Code Lens action")
	end

	-- Visual mode mappings
	vmap("<leader>F", vim.lsp.buf.format, "Format selection")
	vmap("K", vim.lsp.buf.hover, "Hover Documentation")

	-- Insert mode signature help
	imap("<C-k>", vim.lsp.buf.signature_help, "Signature help")
end

function M.setup()
	-- Leader key
	vim.g.mapleader = " "
	vim.g.maplocalleader = " "

	-- General keymaps with validation
	safe_keymap("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlighting" })
	safe_keymap("n", "<C-s>", "<cmd>w<CR>", { desc = "Save file" })
	safe_keymap("i", "<C-s>", "<Esc><cmd>w<CR>", { desc = "Save file from insert mode" })

	-- Window navigation handled by vim-tmux-navigator plugin

	-- Window resizing
	safe_keymap("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
	safe_keymap("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
	safe_keymap("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
	safe_keymap("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

	-- Buffer navigation
	safe_keymap("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
	safe_keymap("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
	safe_keymap("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

	-- Better indenting
	safe_keymap("v", "<", "<gv", { desc = "Indent left and keep selection" })
	safe_keymap("v", ">", ">gv", { desc = "Indent right and keep selection" })

	-- Move text up and down
	safe_keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
	safe_keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
	safe_keymap("x", "J", ":move '>+1<CR>gv-gv", { desc = "Move selection down" })
	safe_keymap("x", "K", ":move '<-2<CR>gv-gv", { desc = "Move selection up" })

	-- Better paste
	safe_keymap("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })

	-- Keep cursor centered
	safe_keymap("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
	safe_keymap("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
	safe_keymap("n", "n", "nzzzv", { desc = "Next search result and center" })
	safe_keymap("n", "N", "Nzzzv", { desc = "Previous search result and center" })

	-- Terminal
	safe_keymap("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
	-- Terminal window navigation handled by vim-tmux-navigator plugin

	-- Quick commands
	safe_keymap("n", "<leader>x", "<cmd>!chmod +x %<CR>", { desc = "Make file executable" })
	safe_keymap("n", "<leader>fx", "<cmd>source %<CR>", { desc = "Source current file" })

	-- Toggle options
	safe_keymap("n", "<leader>tw", "<cmd>set wrap!<CR>", { desc = "Toggle word wrap" })
	safe_keymap("n", "<leader>tn", "<cmd>set number!<CR>", { desc = "Toggle line numbers" })
	safe_keymap("n", "<leader>tr", "<cmd>set relativenumber!<CR>", { desc = "Toggle relative numbers" })
	safe_keymap("n", "<leader>ts", "<cmd>set spell!<CR>", { desc = "Toggle spell check" })

	-- Macro shortcuts
	safe_keymap("n", "Q", "@q", { desc = "Execute macro q" })
	safe_keymap("v", "Q", ":norm @q<CR>", { desc = "Execute macro q on selection" })
end

-- LSP keymap loader with enhanced validation
function M.load_lsp_keymaps(bufnr)
	-- Validate that we have LSP capabilities before setting keymaps
	local clients = vim.lsp.get_clients({ bufnr = bufnr })
	if #clients == 0 then
		vim.notify("No active LSP clients for buffer " .. bufnr, vim.log.levels.WARN)
		return
	end

	-- Create LSP keymaps with validation
	create_lsp_keymap(bufnr)

	-- Auto-formatting on save for supported file types
	local client = clients[1] -- Use first available client
	if client.server_capabilities.documentFormattingProvider then
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format({ bufnr = bufnr })
			end,
			desc = "Auto-format on save",
		})
	end
end

return M
