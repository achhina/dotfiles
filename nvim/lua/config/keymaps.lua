local M = {}

function M.load_keymaps()
	-- [[ Basic Keymaps ]]

	-- Keymaps for better default experience
	-- See `:help vim.keymap.set()`
	vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

	-- Remap for dealing with word wrap
	vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
	vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

	-- Window splitting and management keymaps
	vim.keymap.set("n", "<leader>S", ":split<CR>", { noremap = true, silent = true })
	vim.keymap.set("n", "<leader>V", ":vsplit<CR>", { noremap = true, silent = true })

	-- Play macro in q register
	vim.keymap.set("n", "@q", "Q", { noremap = true, silent = true })
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

	-- We want to reload the launch.json everytime we start our debugger.
	-- [TODO] Use path relative to workspace of current LSP client.
	local continue = function()
		if vim.fn.filereadable(".vscode/launch.json") then
			dap.ext.vscode.load_launchjs()
		end
		return dap.continue
	end

	nmap("<leader>ds", dap.step_into, "[S]tep into")
	nmap("<leader>dS", dap.step_back, "[S]tep back")
	nmap("<leader>dn", dap.step_over, "[N]ext | [S]tep Over")
	nmap("<leader>dds", dap.step_out, "[D] [S]tep Out")
	nmap("<leader>dc", continue, "[C]ontinue")
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
