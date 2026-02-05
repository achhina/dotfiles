return {
	"ibhagwan/fzf-lua",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"folke/trouble.nvim",
	},
	config = function()
		local fzf = require("fzf-lua")

		-- Helper: Send selections to Trouble quickfix
		local function send_to_trouble(action_fn)
			return function(selected, opts)
				action_fn(selected, opts)
				local has_trouble = pcall(require, "trouble")
				if has_trouble then
					vim.cmd("Trouble qflist open focus=true")
				else
					vim.cmd("copen")
				end
			end
		end

		-- Helper: Navigate quickfix list safely with wrapping
		local function safe_qf_navigate(move_cmd, wrap_cmd, wrap_msg)
			local qf_list = vim.fn.getqflist()
			if #qf_list == 0 then
				vim.notify("No quickfix items", vim.log.levels.WARN)
				return
			end

			if wrap_cmd then
				local ok = pcall(function()
					vim.cmd(move_cmd)
				end)
				if not ok then
					vim.cmd(wrap_cmd)
					vim.notify(wrap_msg, vim.log.levels.INFO)
				end
			else
				vim.cmd(move_cmd)
			end
		end

		fzf.setup({
			"default-title",
			winopts = {
				height = 0.85,
				width = 0.80,
				row = 0.35,
				col = 0.50,
				border = "rounded",
				preview = {
					border = "border",
					wrap = false,
					hidden = false,
					vertical = "down:45%",
					horizontal = "right:50%",
					layout = "flex",
					flip_columns = 120,
				},
			},
			keymap = {
				builtin = {
					["<C-d>"] = "preview-page-down",
					["<C-u>"] = "preview-page-up",
					["<S-left>"] = "preview-page-reset",
				},
				fzf = {
					["ctrl-q"] = "select-all+accept",
				},
			},
			actions = {
				files = {
					["default"] = require("fzf-lua.actions").file_edit,
					["ctrl-q"] = send_to_trouble(require("fzf-lua.actions").file_sel_to_qf),
				},
				buffers = {
					["default"] = require("fzf-lua.actions").buf_edit,
					["ctrl-q"] = send_to_trouble(require("fzf-lua.actions").buf_sel_to_qf),
				},
			},
			previewers = {
				cat = {
					cmd = "cat",
					args = "--number",
				},
				bat = {
					cmd = "bat",
					args = "--style=numbers,changes --color always",
					theme = "Coldark-Dark",
				},
				head = {
					cmd = "head",
					args = nil,
				},
				git_diff = {
					cmd_deleted = "git show HEAD:./%s",
					cmd_modified = "git diff HEAD %s",
					cmd_untracked = "git diff --no-index /dev/null %s",
				},
			},
			files = {
				prompt = "Files❯ ",
				multiprocess = true,
				git_icons = true,
				file_icons = true,
				color_icons = true,
				find_opts = [[-type f -not -path '*/\.git/*' -printf '%P\n']],
				rg_opts = "--color=never --files --hidden --follow -g '!.git'",
				fd_opts = "--color=never --type f --hidden --follow --exclude .git",
			},
			grep = {
				prompt = "Rg❯ ",
				input_prompt = "Grep For❯ ",
				multiprocess = true,
				git_icons = true,
				file_icons = true,
				color_icons = true,
				rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
				glob_flag = "--iglob",
				glob_separator = "%s%-%-",
			},
			buffers = {
				prompt = "Buffers❯ ",
				file_icons = true,
				color_icons = true,
				sort_lastused = true,
				ignore_current_buffer = true,
			},
			tabs = {
				prompt = "Tabs❯ ",
				tab_title = "Tab",
				tab_marker = "<<",
				file_icons = true,
				color_icons = true,
			},
			lines = {
				previewer = "builtin",
				prompt = "Lines❯ ",
				show_line_numbers = true,
				show_unlisted = true,
				no_term_buffers = true,
				fzf_opts = {
					["--delimiter"] = ":",
					["--nth"] = "2..",
					["--tiebreak"] = "index",
				},
			},
		})

		vim.keymap.set("n", "<leader>s", "", { desc = "+search" })
		vim.keymap.set("n", "<leader>q", "", { desc = "+quickfix" })

		vim.keymap.set("n", "<leader>sf", function()
			fzf.combine({
				pickers = "oldfiles;files",
				cwd_only = true,
			})
		end, { desc = "Search Files (Recent First)" })
		vim.keymap.set("n", "<leader>fr", fzf.oldfiles, { desc = "Find Recently Opened Files" })
		vim.keymap.set("n", "<leader><space>", fzf.buffers, { desc = "Find Existing Buffers" })

		-- Git keymaps (only in git repositories)
		local in_git_repo = vim.fn.isdirectory(".git") == 1
			or vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null"):match("true")
		if in_git_repo then
			vim.keymap.set("n", "<leader>gf", fzf.git_files, { desc = "Search Git Files" })
			vim.keymap.set("n", "<leader>gc", fzf.git_commits, { desc = "Git Commits" })
			vim.keymap.set("n", "<leader>gb", fzf.git_branches, { desc = "Git Branches" })
			vim.keymap.set("n", "<leader>gs", fzf.git_status, { desc = "Git Status" })
			vim.keymap.set("n", "<leader>gS", fzf.git_stash, { desc = "Git Stash" })
		end

		vim.keymap.set("n", "<leader>sg", fzf.live_grep, { desc = "Search by Grep" })
		vim.keymap.set("n", "<leader>sw", fzf.grep_cword, { desc = "Search Current Word" })
		vim.keymap.set("n", "<leader>sW", fzf.grep_cWORD, { desc = "Search Current WORD" })
		vim.keymap.set("n", "<leader>sb", fzf.blines, { desc = "Search in Buffer" })
		vim.keymap.set("n", "<leader>/", fzf.blines, { desc = "Fuzzily Search in Current Buffer" })

		-- LSP keymaps (set per-buffer on LSP attach)
		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local bufnr = args.buf
				vim.keymap.set("n", "<leader>lr", fzf.lsp_references, { buffer = bufnr, desc = "LSP References" })
				vim.keymap.set("n", "<leader>ld", fzf.lsp_definitions, { buffer = bufnr, desc = "LSP Definitions" })
				vim.keymap.set(
					"n",
					"<leader>li",
					fzf.lsp_implementations,
					{ buffer = bufnr, desc = "LSP Implementations" }
				)
				vim.keymap.set("n", "<leader>lt", fzf.lsp_typedefs, { buffer = bufnr, desc = "LSP Type Definitions" })
				vim.keymap.set(
					"n",
					"<leader>ls",
					fzf.lsp_document_symbols,
					{ buffer = bufnr, desc = "LSP Document Symbols" }
				)
				vim.keymap.set(
					"n",
					"<leader>lS",
					fzf.lsp_workspace_symbols,
					{ buffer = bufnr, desc = "LSP Workspace Symbols" }
				)
			end,
		})

		vim.keymap.set("n", "<leader>sd", fzf.diagnostics_document, { desc = "Search Diagnostics" })

		vim.keymap.set("n", "<leader>sh", fzf.help_tags, { desc = "Search Help" })
		vim.keymap.set("n", "<leader>sc", fzf.commands, { desc = "Search Commands" })
		vim.keymap.set("n", "<leader>sk", fzf.keymaps, { desc = "Search Keymaps" })
		vim.keymap.set("n", "<leader>sr", fzf.registers, { desc = "Search Registers" })
		vim.keymap.set("n", "<leader>sm", fzf.marks, { desc = "Search Marks" })
		vim.keymap.set("n", "<leader>sj", fzf.jumps, { desc = "Search Jumplist" })
		vim.keymap.set("n", "<leader>st", fzf.colorschemes, { desc = "Search Themes" })
		vim.keymap.set("n", "<leader>ss", fzf.spell_suggest, { desc = "Spell Suggestions" })

		vim.keymap.set("n", "<leader>sR", fzf.resume, { desc = "Search Resume" })

		-- Fix escape key in fzf terminal buffers
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "fzf",
			callback = function()
				vim.keymap.set("t", "<Esc>", "<C-c>", { buffer = true, silent = true })
				vim.keymap.set("n", "<Esc>", "<C-c>", { buffer = true, silent = true })
			end,
		})

		vim.keymap.set("n", "[d", function()
			vim.diagnostic.jump({ count = -1 })
		end, { desc = "Go to Previous Diagnostic Message" })
		vim.keymap.set("n", "]d", function()
			vim.diagnostic.jump({ count = 1 })
		end, { desc = "Go to Next Diagnostic Message" })
		vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open Floating Diagnostic Message" })

		-- Quickfix keymaps (Trouble is a dependency, so always available)
		vim.keymap.set("n", "<leader>qd", function()
			vim.diagnostic.setqflist({ open = false })
			vim.cmd("cclose")
			vim.cmd("Trouble diagnostics open focus=true")
		end, { desc = "Workspace Diagnostics Tree (Trouble)" })

		vim.keymap.set("n", "<leader>qe", function()
			vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.ERROR, open = false })
			vim.cmd("cclose")
			vim.cmd("Trouble diagnostics open focus=true filter.severity=vim.diagnostic.severity.ERROR")
		end, { desc = "Workspace Errors Tree (Trouble)" })

		vim.keymap.set(
			"n",
			"<leader>qo",
			"<cmd>Trouble qflist open focus=true<cr>",
			{ desc = "Open Quickfix (Trouble)" }
		)
		vim.keymap.set("n", "<leader>qc", "<cmd>Trouble qflist close<cr>", { desc = "Close Quickfix (Trouble)" })

		vim.keymap.set("n", "<leader>qD", function()
			vim.diagnostic.setqflist()
			vim.cmd("copen")
		end, { desc = "Diagnostics to Traditional Quickfix" })
		vim.keymap.set("n", "<leader>qE", function()
			vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.ERROR })
			vim.cmd("copen")
		end, { desc = "Errors to Traditional Quickfix" })
		vim.keymap.set("n", "<leader>qO", ":copen<CR>", { desc = "Open Traditional Quickfix", silent = true })
		vim.keymap.set("n", "<leader>qC", ":cclose<CR>", { desc = "Close Traditional Quickfix", silent = true })

		-- Quickfix navigation with wrapping
		vim.keymap.set("n", "]q", function()
			safe_qf_navigate("cnext", "cfirst", "Wrapped to first quickfix item")
		end, { desc = "Next Quickfix Item", silent = true })

		vim.keymap.set("n", "[q", function()
			safe_qf_navigate("cprev", "clast", "Wrapped to last quickfix item")
		end, { desc = "Previous Quickfix Item", silent = true })

		vim.keymap.set("n", "]Q", function()
			safe_qf_navigate("clast")
		end, { desc = "Last Quickfix Item", silent = true })

		vim.keymap.set("n", "[Q", function()
			safe_qf_navigate("cfirst")
		end, { desc = "First Quickfix Item", silent = true })
	end,
}
