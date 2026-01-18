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
	init = function()
		-- Auto-start Claude Code with session binding.
		-- Using init ensures autocmd is registered before VimEnter fires.
		local claude_autostart_group = vim.api.nvim_create_augroup("ClaudeCodeAutoStart", { clear = true })

		-- Listen for persistence load completion event instead of using hardcoded delays.
		-- This event-driven approach prevents race conditions on slow/fast systems.
		vim.api.nvim_create_autocmd("User", {
			pattern = "PersistenceLoadPost",
			group = claude_autostart_group,
			callback = function()
				-- Only auto-start if nvim was started without arguments (same condition as persistence)
				if vim.fn.argc(-1) == 0 then
					local cwd = vim.fn.getcwd()
					local session_dir = vim.fn.stdpath("state") .. "/sessions"

					-- Compute session file name matching persistence.nvim naming convention.
					-- Format: .claude-session-%encoded%path or .claude-session-%encoded%path%%branch
					-- IMPORTANT: This path encoding must match neovim-session-binder.sh logic.
					-- In Lua patterns, %% produces a single % in the result (Lua escape rules).
					local cwd_encoded = cwd:gsub("/", "%%")

					-- Check if in git repo and get branch.
					-- Must match shell script logic for session file path alignment.
					local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")
					local session_file
					if branch ~= "" and vim.v.shell_error == 0 then
						session_file = session_dir .. "/.claude-session-" .. cwd_encoded .. "%%" .. branch
					else
						session_file = session_dir .. "/.claude-session-" .. cwd_encoded
					end

					-- Try to read Claude session ID if it exists.
					local session_id = nil
					if vim.fn.filereadable(session_file) == 1 then
						local ok, lines = pcall(vim.fn.readfile, session_file)
						if ok and lines and #lines > 0 then
							-- Validate session ID format (alphanumeric, hyphens, underscores only)
							local raw_id = lines[1]
							if raw_id and raw_id:match("^[%w_-]+$") then
								session_id = raw_id
							else
								vim.notify("Invalid Claude session ID format in " .. session_file, vim.log.levels.WARN)
							end
						end
					end

					-- Auto-start Claude with bound session or resume default.
					local terminal = require("claudecode.terminal")
					if session_id then
						-- Resume specific session bound to this Neovim session.
						-- Use shellescape to prevent command injection.
						terminal.open({}, "--resume " .. vim.fn.shellescape(session_id))
					else
						-- No bound session, just resume normally (directory-based).
						terminal.open({}, "--resume")
					end
				end
			end,
		})
	end,
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
