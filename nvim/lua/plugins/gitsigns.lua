return {
	-- Enhanced git integration with signs, hunks, and utilities
	"lewis6991/gitsigns.nvim",
	opts = {
		signs = {
			add = { text = "│" },
			change = { text = "│" },
			delete = { text = "󰍵" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
			untracked = { text = "┆" },
		},
		signs_staged = {
			add = { text = "│" },
			change = { text = "│" },
			delete = { text = "󰍵" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
			untracked = { text = "┆" },
		},
		signs_staged_enable = true,
		signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
		numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
		linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
		word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
		watch_gitdir = {
			follow_files = true,
		},
		auto_attach = true,
		attach_to_untracked = false,
		current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
		current_line_blame_opts = {
			virt_text = true,
			virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
			delay = 1000,
			ignore_whitespace = false,
			virt_text_priority = 100,
		},
		current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
		sign_priority = 6,
		update_debounce = 100,
		status_formatter = nil, -- Use default
		max_file_length = 40000, -- Disable if file is longer than this (in lines)
		preview_config = {
			-- Options passed to nvim_open_win
			border = "single",
			style = "minimal",
			relative = "cursor",
			row = 0,
			col = 1,
		},
		on_attach = function(bufnr)
			local gitsigns = require("gitsigns")

			local function map(mode, l, r, opts)
				opts = opts or {}
				opts.buffer = bufnr
				vim.keymap.set(mode, l, r, opts)
			end

			-- Navigation
			map("n", "]c", function()
				if vim.wo.diff then
					vim.cmd.normal({ "]c", bang = true })
				else
					---@diagnostic disable-next-line: param-type-mismatch
					gitsigns.nav_hunk("next", { navigation_message = false })
				end
			end, { desc = "Next git hunk" })

			map("n", "[c", function()
				if vim.wo.diff then
					vim.cmd.normal({ "[c", bang = true })
				else
					---@diagnostic disable-next-line: param-type-mismatch
					gitsigns.nav_hunk("prev", { navigation_message = false })
				end
			end, { desc = "Previous git hunk" })

			-- Git hunk actions
			map("n", "<leader>ghs", gitsigns.stage_hunk, { desc = "Stage hunk" })
			map("n", "<leader>ghr", gitsigns.reset_hunk, { desc = "Reset hunk" })
			map("v", "<leader>ghs", function()
				gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, { desc = "Stage hunk" })
			map("v", "<leader>ghr", function()
				gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, { desc = "Reset hunk" })
			map("n", "<leader>ghS", gitsigns.stage_buffer, { desc = "Stage buffer" })
			map("n", "<leader>ghu", gitsigns.reset_buffer_index, { desc = "Undo stage hunk" })
			map("n", "<leader>ghR", gitsigns.reset_buffer, { desc = "Reset buffer" })
			map("n", "<leader>ghp", gitsigns.preview_hunk_inline, { desc = "Preview hunk" })
			map("n", "<leader>ghb", function()
				gitsigns.blame_line({ full = true })
			end, { desc = "Blame line" })
			map("n", "<leader>ghd", gitsigns.diffthis, { desc = "Diff against index" })
			map("n", "<leader>ghD", function()
				---@diagnostic disable-next-line: param-type-mismatch
				gitsigns.diffthis("HEAD~1")
			end, { desc = "Diff against last commit" })

			-- Toggles
			map("n", "<leader>gtb", gitsigns.toggle_current_line_blame, { desc = "Toggle git blame line" })
			map("n", "<leader>gtl", gitsigns.toggle_linehl, { desc = "Toggle git blame highlights" })
			map("n", "<leader>gtd", function()
				gitsigns.toggle_deleted()
			end, { desc = "Toggle git show deleted" })

			-- Text object
			map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select git hunk" })
		end,
	},
}
