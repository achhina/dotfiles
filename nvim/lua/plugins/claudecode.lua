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
		local claude_autostart_group = vim.api.nvim_create_augroup("ClaudeCodeAutoStart", { clear = true })
		local session_dir = vim.fn.stdpath("state") .. "/sessions"

		local function get_state_file_path()
			local cwd = vim.fn.getcwd()
			local cwd_encoded = cwd:gsub("/", "%%")
			local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")

			if branch ~= "" and vim.v.shell_error == 0 then
				return session_dir .. "/.claude-state-" .. cwd_encoded .. "%%" .. branch
			else
				return session_dir .. "/.claude-state-" .. cwd_encoded
			end
		end

		local function get_session_id_path()
			local cwd = vim.fn.getcwd()
			local cwd_encoded = cwd:gsub("/", "%%")
			local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")

			if branch ~= "" and vim.v.shell_error == 0 then
				return session_dir .. "/.claude-session-" .. cwd_encoded .. "%%" .. branch
			else
				return session_dir .. "/.claude-session-" .. cwd_encoded
			end
		end

		-- Save Claude state before session saves
		vim.api.nvim_create_autocmd("User", {
			pattern = "PersistenceSavePre",
			group = claude_autostart_group,
			callback = function()
				local terminal = require("claudecode.terminal")
				local claude_bufnr = terminal.get_active_terminal_bufnr()

				if claude_bufnr then
					-- Claude is open, save marker
					vim.fn.writefile({ "1" }, get_state_file_path())
				else
					-- Claude is closed, remove marker
					vim.fn.delete(get_state_file_path())
				end
			end,
		})

		-- Delete state file when Claude buffer is closed
		vim.api.nvim_create_autocmd("BufDelete", {
			group = claude_autostart_group,
			callback = function(args)
				if vim.bo[args.buf].buftype == "terminal" then
					local bufname = vim.api.nvim_buf_get_name(args.buf)
					if bufname:match("claude") then
						vim.fn.delete(get_state_file_path())
					end
				end
			end,
		})

		-- Restore Claude on session load
		vim.api.nvim_create_autocmd("User", {
			pattern = "PersistenceLoadPost",
			group = claude_autostart_group,
			callback = function()
				if vim.fn.argc(-1) > 0 then
					return
				end

				-- Check if state file exists
				local state_file = get_state_file_path()
				if vim.fn.filereadable(state_file) == 0 then
					return
				end

				-- Go to tab 1
				vim.cmd("tabnext 1")

				-- Read session ID
				local session_file = get_session_id_path()
				local session_id = nil
				if vim.fn.filereadable(session_file) == 1 then
					local ok, lines = pcall(vim.fn.readfile, session_file)
					if ok and lines and #lines > 0 then
						local raw_id = lines[1]
						if raw_id and raw_id:match("^[%w_-]+$") then
							session_id = raw_id
						end
					end
				end

				-- Start Claude
				local terminal = require("claudecode.terminal")
				if session_id then
					terminal.open({}, "--resume " .. vim.fn.shellescape(session_id))
				else
					terminal.open({}, "--resume")
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
