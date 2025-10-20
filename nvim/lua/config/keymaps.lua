local M = {}

local function safe_keymap(mode, lhs, rhs, opts, bufnr)
	opts = opts or {}

	if rhs == nil then
		vim.notify("Skipping invalid keymap: " .. lhs .. " -> nil", vim.log.levels.WARN)
		return false
	end

	if type(rhs) == "function" then
		if bufnr then
			opts.buffer = bufnr
		end
		vim.keymap.set(mode, lhs, rhs, opts)
		return true
	end

	if type(rhs) == "string" then
		if bufnr then
			opts.buffer = bufnr
		end
		vim.keymap.set(mode, lhs, rhs, opts)
		return true
	end

	vim.notify(
		"Skipping invalid keymap: " .. lhs .. " -> " .. tostring(rhs) .. " (type: " .. type(rhs) .. ")",
		vim.log.levels.WARN
	)
	return false
end

local function create_lsp_keymap(bufnr)
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

	local has_fzf, fzf_lua = pcall(require, "fzf-lua")

	-- Core LSP navigation with fzf-lua fallbacks
	nmap("gD", vim.lsp.buf.declaration, "Goto Declaration")
	nmap("gd", vim.lsp.buf.definition, "Goto Definition")
	nmap("gI", vim.lsp.buf.implementation, "Goto Implementation")
	nmap("<leader>D", vim.lsp.buf.type_definition, "Type Definition")

	if has_fzf and fzf_lua.lsp_references then
		nmap("gr", fzf_lua.lsp_references, "Goto References")
	else
		nmap("gr", vim.lsp.buf.references, "Goto References")
	end

	if has_fzf and fzf_lua.lsp_document_symbols then
		nmap("<leader>sy", fzf_lua.lsp_document_symbols, "Document Symbols")
	else
		nmap("<leader>sy", vim.lsp.buf.document_symbol, "Document Symbols")
	end

	if has_fzf and fzf_lua.lsp_workspace_symbols then
		nmap("<leader>ws", fzf_lua.lsp_workspace_symbols, "Workspace Symbols")
	else
		nmap("<leader>ws", vim.lsp.buf.workspace_symbol, "Workspace Symbols")
	end

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

	if vim.lsp.buf.incoming_calls then
		nmap("<leader>ci", vim.lsp.buf.incoming_calls, "Incoming calls")
	end
	if vim.lsp.buf.outgoing_calls then
		nmap("<leader>co", vim.lsp.buf.outgoing_calls, "Outgoing calls")
	end
	if vim.lsp.buf.type_hierarchy then
		nmap("<leader>lT", vim.lsp.buf.type_hierarchy, "Type Hierarchy")
	end
	if vim.lsp.codelens and vim.lsp.codelens.run then
		nmap("<leader>cl", vim.lsp.codelens.run, "Code Lens action")
	end

	vmap("<leader>F", vim.lsp.buf.format, "Format selection")
	vmap("K", vim.lsp.buf.hover, "Hover Documentation")
	imap("<C-k>", vim.lsp.buf.signature_help, "Signature help")
end

function M.setup()
	vim.g.mapleader = " "
	vim.g.maplocalleader = " "

	safe_keymap("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlighting" })
	safe_keymap("n", "<C-s>", "<cmd>w<CR>", { desc = "Save file" })
	safe_keymap("i", "<C-s>", "<Esc><cmd>w<CR>", { desc = "Save file from insert mode" })

	safe_keymap("n", "<leader>v", "<cmd>vsplit<CR>", { desc = "Vertical split" })
	safe_keymap("n", "<leader>h", "<cmd>split<CR>", { desc = "Horizontal split" })

	safe_keymap("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
	safe_keymap("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
	safe_keymap("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
	safe_keymap("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

	safe_keymap("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
	safe_keymap("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
	safe_keymap("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

	safe_keymap("v", "<", "<gv", { desc = "Indent left and keep selection" })
	safe_keymap("v", ">", ">gv", { desc = "Indent right and keep selection" })

	safe_keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
	safe_keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
	safe_keymap("x", "J", ":move '>+1<CR>gv-gv", { desc = "Move selection down" })
	safe_keymap("x", "K", ":move '<-2<CR>gv-gv", { desc = "Move selection up" })

	safe_keymap("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })

	safe_keymap("n", "j", "gj", { desc = "Move down by display line" })
	safe_keymap("n", "k", "gk", { desc = "Move up by display line" })

	safe_keymap("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
	safe_keymap("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
	safe_keymap("n", "n", "nzzzv", { desc = "Next search result and center" })
	safe_keymap("n", "N", "Nzzzv", { desc = "Previous search result and center" })

	safe_keymap("n", "<leader>X", "<cmd>!chmod +x %<CR>", { desc = "Make file executable" })
	safe_keymap("n", "<leader>fx", "<cmd>source %<CR>", { desc = "Source current file" })
	safe_keymap("n", "<leader>Q", "<cmd>qa<CR>", { desc = "Quit all" })

	safe_keymap("t", "<leader><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

	safe_keymap("n", "<leader>ow", "<cmd>set wrap!<CR>", { desc = "Toggle word wrap" })
	safe_keymap("n", "<leader>on", "<cmd>set number!<CR>", { desc = "Toggle line numbers" })
	safe_keymap("n", "<leader>or", "<cmd>set relativenumber!<CR>", { desc = "Toggle relative numbers" })
	safe_keymap("n", "<leader>os", "<cmd>set spell!<CR>", { desc = "Toggle spell check" })

	safe_keymap("n", "Q", "@q", { desc = "Execute macro q" })
	safe_keymap("v", "Q", ":norm @q<CR>", { desc = "Execute macro q on selection" })
end

function M.load_lsp_keymaps(bufnr)
	local clients = vim.lsp.get_clients({ bufnr = bufnr })
	if #clients == 0 then
		vim.notify("No active LSP clients for buffer " .. bufnr, vim.log.levels.WARN)
		return
	end

	create_lsp_keymap(bufnr)

	local client = clients[1]
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

function M.load_dap_keymaps()
	local dap = require("dap")
	local dapui = require("dapui")

	-- Core debugging controls
	safe_keymap("n", "<leader>ds", dap.continue, { desc = "Debug: Start/Continue" })
	safe_keymap("n", "<leader>dS", dap.close, { desc = "Debug: Stop" })
	safe_keymap("n", "<leader>dn", dap.step_over, { desc = "Debug: Step Over" })
	safe_keymap("n", "<leader>di", dap.step_into, { desc = "Debug: Step Into" })
	safe_keymap("n", "<leader>do", dap.step_out, { desc = "Debug: Step Out" })
	safe_keymap("n", "<leader>dc", dap.run_to_cursor, { desc = "Debug: Run to Cursor" })
	safe_keymap("n", "<leader>dr", dap.restart, { desc = "Debug: Restart" })

	safe_keymap("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
	safe_keymap("n", "<leader>dB", function()
		dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
	end, { desc = "Debug: Conditional Breakpoint" })
	safe_keymap("n", "<leader>dl", function()
		dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
	end, { desc = "Debug: Log Point" })

	safe_keymap("n", "<leader>de", dapui.eval, { desc = "Debug: Evaluate Expression" })
	safe_keymap("v", "<leader>de", dapui.eval, { desc = "Debug: Evaluate Selection" })
	safe_keymap("n", "<leader>dE", function()
		dapui.eval(vim.fn.input("Expression: "))
	end, { desc = "Debug: Evaluate Input" })
	safe_keymap("n", "<leader>du", dapui.toggle, { desc = "Debug: Toggle UI" })

	safe_keymap("n", "<leader>dR", dap.clear_breakpoints, { desc = "Debug: Clear All Breakpoints" })
	safe_keymap("n", "<leader>dt", dap.terminate, { desc = "Debug: Terminate Session" })

	safe_keymap("n", "<leader>dq", dap.repl.toggle, { desc = "Debug: Toggle REPL" })

	if dap.session then
		safe_keymap("n", "<leader>dh", function()
			dapui.hover()
		end, { desc = "Debug: Hover Variables" })
	end
end

-- Test execution
safe_keymap("n", "<leader>tn", function()
	local has_neotest, neotest = pcall(require, "neotest")
	if has_neotest then
		neotest.run.run()
	else
		vim.notify("Neotest not available", vim.log.levels.WARN)
	end
end, { desc = "Run nearest test" })

safe_keymap("n", "<leader>tf", function()
	local has_neotest, neotest = pcall(require, "neotest")
	if has_neotest then
		neotest.run.run(vim.fn.expand("%"))
	else
		vim.notify("Neotest not available", vim.log.levels.WARN)
	end
end, { desc = "Run current file tests" })

safe_keymap("n", "<leader>td", function()
	local has_neotest, neotest = pcall(require, "neotest")
	if has_neotest then
		neotest.run.run({ strategy = "dap" })
	else
		vim.notify("Neotest not available", vim.log.levels.WARN)
	end
end, { desc = "Debug nearest test" })

safe_keymap("n", "<leader>ts", function()
	local has_neotest, neotest = pcall(require, "neotest")
	if has_neotest then
		neotest.summary.toggle()
	else
		vim.notify("Neotest not available", vim.log.levels.WARN)
	end
end, { desc = "Toggle test summary" })

safe_keymap("n", "<leader>to", function()
	local has_neotest, neotest = pcall(require, "neotest")
	if has_neotest then
		neotest.output.open({ enter = true, auto_close = true })
	else
		vim.notify("Neotest not available", vim.log.levels.WARN)
	end
end, { desc = "Show test output" })

safe_keymap("n", "<leader>tO", function()
	local has_neotest, neotest = pcall(require, "neotest")
	if has_neotest then
		neotest.output_panel.toggle()
	else
		vim.notify("Neotest not available", vim.log.levels.WARN)
	end
end, { desc = "Toggle test output panel" })

safe_keymap("n", "<leader>tr", function()
	local has_neotest, neotest = pcall(require, "neotest")
	if has_neotest then
		neotest.run.run_last()
	else
		vim.notify("Neotest not available", vim.log.levels.WARN)
	end
end, { desc = "Run last test" })

safe_keymap("n", "<leader>tS", function()
	local has_neotest, neotest = pcall(require, "neotest")
	if has_neotest then
		neotest.run.stop()
	else
		vim.notify("Neotest not available", vim.log.levels.WARN)
	end
end, { desc = "Stop running tests" })

return M
