return {
	"ibhagwan/fzf-lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local fzf = require("fzf-lua")

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
					wrap = "nowrap",
					hidden = "nohidden",
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
					["ctrl-q"] = function(selected, opts)
						require("fzf-lua.actions").file_sel_to_qf(selected, opts)
						vim.cmd("copen")
					end,
				},
				buffers = {
					["default"] = require("fzf-lua.actions").buf_edit,
					["ctrl-q"] = function(selected, opts)
						require("fzf-lua.actions").buf_sel_to_qf(selected, opts)
						vim.cmd("copen")
					end,
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

		-- Search namespace
		vim.keymap.set("n", "<leader>s", "", { desc = "+search" })

		-- File pickers
		vim.keymap.set("n", "<leader>sf", fzf.files, { desc = "Search Files" })
		vim.keymap.set("n", "<leader>fr", fzf.oldfiles, { desc = "Find recently opened files" })
		vim.keymap.set("n", "<leader><space>", fzf.buffers, { desc = "Find existing buffers" })
		vim.keymap.set("n", "<leader>gf", fzf.git_files, { desc = "Search Git Files" })

		-- Search pickers
		vim.keymap.set("n", "<leader>sg", fzf.live_grep, { desc = "Search by Grep" })
		vim.keymap.set("n", "<leader>sw", fzf.grep_cword, { desc = "Search current Word" })
		vim.keymap.set("n", "<leader>sW", fzf.grep_cWORD, { desc = "Search current WORD" })
		vim.keymap.set("n", "<leader>sb", fzf.blines, { desc = "Search in Buffer" })
		vim.keymap.set("n", "<leader>/", fzf.blines, { desc = "Fuzzily search in current buffer" })

		-- Git pickers
		vim.keymap.set("n", "<leader>gc", fzf.git_commits, { desc = "Git Commits" })
		vim.keymap.set("n", "<leader>gb", fzf.git_branches, { desc = "Git Branches" })
		vim.keymap.set("n", "<leader>gs", fzf.git_status, { desc = "Git Status" })
		vim.keymap.set("n", "<leader>gt", fzf.git_stash, { desc = "Git stash" })

		-- LSP pickers
		vim.keymap.set("n", "<leader>lr", fzf.lsp_references, { desc = "LSP References" })
		vim.keymap.set("n", "<leader>ld", fzf.lsp_definitions, { desc = "LSP Definitions" })
		vim.keymap.set("n", "<leader>li", fzf.lsp_implementations, { desc = "LSP Implementations" })
		vim.keymap.set("n", "<leader>lt", fzf.lsp_typedefs, { desc = "LSP Type definitions" })
		vim.keymap.set("n", "<leader>ls", fzf.lsp_document_symbols, { desc = "LSP document Symbols" })
		vim.keymap.set("n", "<leader>lS", fzf.lsp_workspace_symbols, { desc = "LSP workspace Symbols" })
		vim.keymap.set("n", "<leader>sd", fzf.diagnostics_document, { desc = "Search Diagnostics" })

		-- Utility pickers
		vim.keymap.set("n", "<leader>sh", fzf.help_tags, { desc = "Search Help" })
		vim.keymap.set("n", "<leader>sc", fzf.commands, { desc = "Search Commands" })
		vim.keymap.set("n", "<leader>sk", fzf.keymaps, { desc = "Search Keymaps" })
		vim.keymap.set("n", "<leader>sr", fzf.registers, { desc = "Search Registers" })
		vim.keymap.set("n", "<leader>sm", fzf.marks, { desc = "Search Marks" })
		vim.keymap.set("n", "<leader>sj", fzf.jumps, { desc = "Search Jumplist" })
		vim.keymap.set("n", "<leader>st", fzf.colorschemes, { desc = "Search Themes" })
		vim.keymap.set("n", "<leader>ss", fzf.spell_suggest, { desc = "Spell Suggestions" })

		-- Resume last picker
		vim.keymap.set("n", "<leader>sR", fzf.resume, { desc = "Search Resume" })

		-- Fix escape key in fzf terminal buffers
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "fzf",
			callback = function()
				-- Map escape in terminal mode to close fzf
				vim.keymap.set("t", "<Esc>", "<C-c>", { buffer = true, silent = true })
				-- Map escape in normal mode within fzf buffer to close fzf
				vim.keymap.set("n", "<Esc>", "<C-c>", { buffer = true, silent = true })
			end,
		})

		-- Diagnostic keymaps
		vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
		vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
		vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })

		-- Quickfix keymaps (using Trouble by default)
		vim.keymap.set(
			"n",
			"<leader>qd",
			"<cmd>Trouble diagnostics open focus=true<cr>",
			{ desc = "Diagnostics (Trouble)" }
		)
		vim.keymap.set(
			"n",
			"<leader>qe",
			"<cmd>Trouble diagnostics open focus=true filter.severity=vim.diagnostic.severity.ERROR<cr>",
			{ desc = "Errors (Trouble)" }
		)
		vim.keymap.set(
			"n",
			"<leader>qo",
			"<cmd>Trouble qflist open focus=true<cr>",
			{ desc = "Open quickfix (Trouble)" }
		)
		vim.keymap.set("n", "<leader>qc", "<cmd>Trouble qflist close<cr>", { desc = "Close quickfix (Trouble)" })

		-- Traditional quickfix (for when you need the actual quickfix list)
		vim.keymap.set("n", "<leader>qD", function()
			vim.diagnostic.setqflist()
			vim.cmd("copen")
		end, { desc = "Diagnostics to traditional quickfix" })
		vim.keymap.set("n", "<leader>qE", function()
			vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.ERROR })
			vim.cmd("copen")
		end, { desc = "Errors to traditional quickfix" })
		vim.keymap.set("n", "<leader>qO", ":copen<CR>", { desc = "Open traditional quickfix", silent = true })
		vim.keymap.set("n", "<leader>qC", ":cclose<CR>", { desc = "Close traditional quickfix", silent = true })

		-- Quickfix navigation with error handling
		vim.keymap.set("n", "]q", function()
			local qf_list = vim.fn.getqflist()
			if #qf_list == 0 then
				vim.notify("No quickfix items", vim.log.levels.WARN)
				return
			end
			local ok = pcall(vim.cmd, "cnext")
			if not ok then
				vim.cmd("cfirst")
				vim.notify("Wrapped to first quickfix item", vim.log.levels.INFO)
			end
		end, { desc = "Next quickfix item", silent = true })

		vim.keymap.set("n", "[q", function()
			local qf_list = vim.fn.getqflist()
			if #qf_list == 0 then
				vim.notify("No quickfix items", vim.log.levels.WARN)
				return
			end
			local ok = pcall(vim.cmd, "cprev")
			if not ok then
				vim.cmd("clast")
				vim.notify("Wrapped to last quickfix item", vim.log.levels.INFO)
			end
		end, { desc = "Previous quickfix item", silent = true })

		vim.keymap.set("n", "]Q", function()
			local qf_list = vim.fn.getqflist()
			if #qf_list == 0 then
				vim.notify("No quickfix items", vim.log.levels.WARN)
				return
			end
			vim.cmd("clast")
		end, { desc = "Last quickfix item", silent = true })

		vim.keymap.set("n", "[Q", function()
			local qf_list = vim.fn.getqflist()
			if #qf_list == 0 then
				vim.notify("No quickfix items", vim.log.levels.WARN)
				return
			end
			vim.cmd("cfirst")
		end, { desc = "First quickfix item", silent = true })
	end,
}
