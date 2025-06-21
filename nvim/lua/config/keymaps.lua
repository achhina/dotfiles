local M = {}

-- Helper function for easier keymap creation
local function map(mode, lhs, rhs, opts)
	opts = opts or {}
	opts.silent = opts.silent ~= false
	vim.keymap.set(mode, lhs, rhs, opts)
end

function M.load_keymaps()
	-- [[ Basic Keymaps ]]

	-- Disable space in normal and visual mode (leader key)
	map({ "n", "v" }, "<Space>", "<Nop>")

	-- Better navigation with word wrap
	map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })
	map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })

	-- Clear search highlighting
	map("n", "<Esc>", "<cmd>nohlsearch<CR>")
	map("n", "<leader>/", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

	-- Better indenting
	map("v", "<", "<gv", { desc = "Indent left and reselect" })
	map("v", ">", ">gv", { desc = "Indent right and reselect" })

	-- Move lines up/down
	map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
	map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
	map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move line down" })
	map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move line up" })
	map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
	map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

	-- Better paste (don't overwrite register)
	map("v", "p", '"_dP', { desc = "Paste without overwriting register" })

	-- Delete to black hole register
	map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete to black hole register" })

	-- Copy to system clipboard
	map({ "n", "v" }, "<leader>y", '"+y', { desc = "Copy to system clipboard" })
	map("n", "<leader>Y", '"+Y', { desc = "Copy line to system clipboard" })

	-- Paste from system clipboard
	map({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })
	map({ "n", "v" }, "<leader>P", '"+P', { desc = "Paste before from system clipboard" })

	-- Window management
	map("n", "<leader>wv", "<C-w>v", { desc = "Split window vertically" })
	map("n", "<leader>wh", "<C-w>s", { desc = "Split window horizontally" })
	map("n", "<leader>we", "<C-w>=", { desc = "Make windows equal size" })
	map("n", "<leader>wx", "<cmd>close<CR>", { desc = "Close current window" })
	map("n", "<leader>wm", "<cmd>MaximizerToggle<CR>", { desc = "Toggle window maximize" })

	-- Window navigation (handled by vim-tmux-navigator plugin)

	-- Resize windows
	map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
	map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
	map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
	map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

	-- Buffer management
	map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
	map("n", "<leader>bD", "<cmd>bdelete!<CR>", { desc = "Force delete buffer" })
	map("n", "<leader>ba", "<cmd>%bdelete|edit#|bdelete#<CR>", { desc = "Delete all buffers but current" })
	map("n", "<leader>bl", "<cmd>blast<CR>", { desc = "Go to last buffer" })
	map("n", "<leader>bf", "<cmd>bfirst<CR>", { desc = "Go to first buffer" })

	-- Buffer navigation
	map("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
	map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
	map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
	map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

	-- Tab management
	map("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
	map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
	map("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
	map("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
	map("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })

	-- Quickfix list
	map("n", "[q", "<cmd>cprevious<CR>", { desc = "Previous quickfix item" })
	map("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix item" })
	map("n", "<leader>q", function()
		vim.diagnostic.setloclist()
		vim.cmd("lopen")
	end, { desc = "Show diagnostics in location list" })

	-- Open quickfix list
	map("n", "<leader>cq", "<cmd>copen<CR>", { desc = "Open quickfix list" })

	-- Location list
	map("n", "[l", "<cmd>lprevious<CR>", { desc = "Previous location item" })
	map("n", "]l", "<cmd>lnext<CR>", { desc = "Next location item" })
	map("n", "<leader>lo", "<cmd>lopen<CR>", { desc = "Open location list" })
	map("n", "<leader>lc", "<cmd>lclose<CR>", { desc = "Close location list" })

	-- Better command line editing
	map("c", "<C-a>", "<Home>", { desc = "Go to beginning of line" })
	map("c", "<C-e>", "<End>", { desc = "Go to end of line" })
	map("c", "<C-h>", "<Left>", { desc = "Move cursor left" })
	map("c", "<C-l>", "<Right>", { desc = "Move cursor right" })
	map("c", "<C-j>", "<Down>", { desc = "Next command in history" })
	map("c", "<C-k>", "<Up>", { desc = "Previous command in history" })

	-- Insert mode navigation
	map("i", "<C-h>", "<Left>", { desc = "Move cursor left" })
	map("i", "<C-l>", "<Right>", { desc = "Move cursor right" })
	map("i", "<C-j>", "<Down>", { desc = "Move cursor down" })
	map("i", "<C-k>", "<Up>", { desc = "Move cursor up" })

	-- Quick save and quit
	map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
	map("n", "<leader>W", "<cmd>wa<CR>", { desc = "Save all files" })
	map("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Quit all without saving" })

	-- File operations
	map("n", "<leader>fn", "<cmd>enew<CR>", { desc = "New file" })
	map("n", "<leader>fe", "<cmd>e!<CR>", { desc = "Reload file" })
	map("n", "<leader>fr", "<cmd>e<CR>", { desc = "Refresh file" })

	-- Text manipulation
	map("n", "U", "<C-r>", { desc = "Redo" })
	map("n", "<leader>J", "mzJ`z", { desc = "Join lines and restore cursor" })

	-- Center screen on navigation
	map("n", "<C-d>", "<C-d>zz", { desc = "Half page down and center" })
	map("n", "<C-u>", "<C-u>zz", { desc = "Half page up and center" })
	map("n", "n", "nzzzv", { desc = "Next search result and center" })
	map("n", "N", "Nzzzv", { desc = "Previous search result and center" })

	-- Select all
	map("n", "<C-a>", "gg<S-v>G", { desc = "Select all" })

	-- Increment/decrement numbers
	map("n", "<leader>+", "<C-a>", { desc = "Increment number" })
	map("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

	-- Replace word under cursor
	map(
		"n",
		"<leader>rw",
		[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
		{ desc = "Replace word under cursor" }
	)

	-- Make file executable
	map("n", "<leader>x", "<cmd>!chmod +x %<CR>", { desc = "Make file executable" })

	-- Source current file
	map("n", "<leader>fx", "<cmd>source %<CR>", { desc = "Source current file" })

	-- Toggle options
	map("n", "<leader>tw", "<cmd>set wrap!<CR>", { desc = "Toggle word wrap" })
	map("n", "<leader>tn", "<cmd>set number!<CR>", { desc = "Toggle line numbers" })
	map("n", "<leader>tr", "<cmd>set relativenumber!<CR>", { desc = "Toggle relative numbers" })
	map("n", "<leader>ts", "<cmd>set spell!<CR>", { desc = "Toggle spell check" })

	-- Macro shortcuts
	map("n", "Q", "@q", { desc = "Execute macro q" })
	map("v", "Q", ":norm @q<CR>", { desc = "Execute macro q on selection" })
end

function M.load_lsp_keymaps(bufnr)
	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
	nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
	nmap("<leader>F", vim.lsp.buf.format, "[F]ormat document")

	nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
	nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
	nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
	nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
	nmap("<leader>sy", require("telescope.builtin").lsp_document_symbols, "Document [S][y]mbols")
	nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

	nmap("K", vim.lsp.buf.hover, "Hover Documentation")
	nmap("<leader>k", vim.lsp.buf.signature_help, "Signature Documentation")

	-- Lesser used LSP functionality
	nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
	nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
	nmap("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "[W]orkspace [L]ist Folders")

	-- Create a command `:Format` local to the LSP buffer
	vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
		vim.lsp.buf.format()
	end, { desc = "Format current buffer with LSP" })
end

function M.load_dap_keymaps()
	local dap = require("dap")
	local dapui = require("dapui")

	local nmap = function(keys, func, desc)
		if desc then
			desc = "[D]AP: " .. desc
		end
		vim.keymap.set("n", keys, func, { silent = true, desc = desc })
	end

	nmap("<leader>ds", dap.step_into, "[S]tep into")
	nmap("<leader>dS", dap.step_back, "[S]tep back")
	nmap("<leader>dn", dap.step_over, "[N]ext | [S]tep Over")
	nmap("<leader>do", dap.step_out, "[S]tep [O]ut")
	nmap("<leader>dc", dap.continue, "[C]ontinue")
	nmap("<leader>dr", dap.repl.open, "[R]EPL Open")
	nmap("<leader>db", dap.toggle_breakpoint, "Toggle [B]reakpoint")
	nmap("<leader>dB", function()
		dap.set_breakpoint(vim.fn.input("[DAP] Condition > "))
	end, "Set [B]reakpoint")
	nmap("<leader>de", dapui.eval, "[E]valuate")
	nmap("<leader>dE", function()
		dapui.eval(vim.fn.input("[DAP] Expression > "))
	end, "[E]xpression")
end

return M
