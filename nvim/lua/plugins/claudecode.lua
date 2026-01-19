local function send_selection_and_focus()
	local claudecode = require("claudecode")
	local terminal = require("claudecode.terminal")

	local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
	vim.api.nvim_feedkeys(esc, "nx", false)

	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")

	local claude_start_line = start_line and (start_line - 1) or nil
	local claude_end_line = end_line and (end_line - 1) or nil

	claudecode.send_at_mention(vim.fn.expand("%:p"), claude_start_line, claude_end_line)
	terminal.open()
end

local function send_selection_only()
	local claudecode = require("claudecode")
	local terminal = require("claudecode.terminal")

	local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
	vim.api.nvim_feedkeys(esc, "nx", false)

	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")

	local claude_start_line = start_line and (start_line - 1) or nil
	local claude_end_line = end_line and (end_line - 1) or nil

	claudecode.send_at_mention(vim.fn.expand("%:p"), claude_start_line, claude_end_line)
	terminal.ensure_visible()
end

local function send_buffer_and_focus()
	local claudecode = require("claudecode")
	local terminal = require("claudecode.terminal")

	claudecode.send_at_mention(vim.fn.expand("%:p"))
	terminal.open()
end

local function send_buffer_only()
	local claudecode = require("claudecode")
	local terminal = require("claudecode.terminal")

	claudecode.send_at_mention(vim.fn.expand("%:p"))
	terminal.ensure_visible()
end

return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	config = function()
		require("claudecode").setup({
			terminal = {
				split_width_percentage = 0.40,
			},
			env = {
				-- Neovim-specific identifier for session binding hook
				CLAUDE_FROM_NEOVIM = "1",
			},
			diff_opts = {
				open_in_new_tab = true,
				keep_terminal_focus = true,
			},
		})
	end,
	keys = {
		{ "<leader>a", nil, desc = "AI/Claude Code" },
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
		{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
		{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
		{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },

		{ "<leader>as", send_selection_and_focus, mode = "v", desc = "Send selection & focus" },
		{ "<leader>ab", send_buffer_and_focus, mode = "n", desc = "Send buffer & focus" },
		{ "<leader>aS", send_selection_only, mode = "v", desc = "Send selection" },
		{ "<leader>aB", send_buffer_only, mode = "n", desc = "Send buffer" },
		{
			"<leader>as",
			"<cmd>ClaudeCodeTreeAdd<cr>",
			desc = "Add file",
			ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
		},
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
	},
}
