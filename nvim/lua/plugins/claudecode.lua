local temp_files = {}

local function is_file_backed()
	local filepath = vim.fn.expand("%:p")
	return filepath ~= "" and vim.fn.filereadable(filepath) == 1
end

local function create_context_header(bufname, display_name, ext, line_range)
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")

	local header_lines = {
		"<context>",
		"This is an in-memory buffer from the user's IDE (Neovim).",
		"This content is not saved to disk and should be treated as read-only reference material.",
		"",
		"Metadata:",
	}

	table.insert(header_lines, string.format("  Buffer: %s", bufname ~= "" and bufname or "unnamed buffer"))

	if line_range then
		table.insert(header_lines, string.format("  Lines: %d-%d (visual selection)", line_range.start, line_range.stop))
	else
		table.insert(header_lines, "  Lines: entire buffer")
	end

	table.insert(header_lines, string.format("  Timestamp: %s", timestamp))
	table.insert(header_lines, "</context>")
	table.insert(header_lines, "")

	return header_lines
end

local function track_temp_file(filepath)
	table.insert(temp_files, filepath)
end

vim.api.nvim_create_autocmd("VimLeavePre", {
	group = vim.api.nvim_create_augroup("ClaudeCodeTempCleanup", { clear = true }),
	callback = function()
		for _, file in ipairs(temp_files) do
			vim.fn.delete(file)
		end
	end,
})

local function send_selection()
	if is_file_backed() then
		vim.cmd("ClaudeCodeSend")
		vim.cmd("ClaudeCodeFocus")
		return
	end

	-- Get visual selection WHILE STILL IN VISUAL MODE (like upstream does)
	local bufnr = vim.api.nvim_get_current_buf()

	local anchor_pos = vim.fn.getpos("v")
	local cursor_pos = vim.api.nvim_win_get_cursor(0)

	local p1 = { lnum = anchor_pos[2], col = anchor_pos[3] }
	local p2 = { lnum = cursor_pos[1], col = cursor_pos[2] + 1 }

	local start_coords, end_coords
	if p1.lnum < p2.lnum or (p1.lnum == p2.lnum and p1.col <= p2.col) then
		start_coords, end_coords = p1, p2
	else
		start_coords, end_coords = p2, p1
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, start_coords.lnum - 1, end_coords.lnum, false)

	local bufname = vim.api.nvim_buf_get_name(0)
	local display_name = bufname ~= "" and vim.fn.fnamemodify(bufname, ":t") or "unnamed"
	local ext = display_name:match("%.([^.]+)$") or "txt"

	local header = create_context_header(bufname, display_name, ext, {
		start = start_coords.lnum,
		stop = end_coords.lnum
	})
	local content_with_header = vim.list_extend(header, lines)

	local temp_file = vim.fn.tempname() .. "." .. ext
	vim.fn.writefile(content_with_header, temp_file, "b")
	vim.fn.setfperm(temp_file, "rw-r--r--")
	track_temp_file(temp_file)

	vim.notify(
		string.format("[Claude] Sending unsaved buffer '%s' via temp file", display_name),
		vim.log.levels.INFO
	)

	vim.cmd('normal! \\<Esc>')
	vim.cmd(string.format("ClaudeCodeAdd %s", vim.fn.fnameescape(temp_file)))
	vim.cmd("ClaudeCodeFocus")
end

local function add_buffer()
	if is_file_backed() then
		vim.cmd("ClaudeCodeAdd %")
		vim.cmd("ClaudeCodeFocus")
		return
	end

	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	local bufname = vim.api.nvim_buf_get_name(0)
	local display_name = bufname ~= "" and vim.fn.fnamemodify(bufname, ":t") or "unnamed"
	local ext = display_name:match("%.([^.]+)$") or "txt"

	local header = create_context_header(bufname, display_name, ext, nil)
	local content_with_header = vim.list_extend(header, lines)

	local temp_file = vim.fn.tempname() .. "." .. ext
	vim.fn.writefile(content_with_header, temp_file, "b")
	vim.fn.setfperm(temp_file, "rw-r--r--")
	track_temp_file(temp_file)

	vim.notify(
		string.format("[Claude] Sending unsaved buffer '%s' via temp file", display_name),
		vim.log.levels.INFO
	)

	vim.cmd(string.format("ClaudeCodeAdd %s", vim.fn.fnameescape(temp_file)))
	vim.cmd("ClaudeCodeFocus")
end

return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	config = function()
		require("claudecode").setup({
			terminal = {
				provider = "snacks",
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

		{ "<leader>as", send_selection, mode = "v", desc = "Send selection to Claude" },
		{ "<leader>ab", add_buffer, mode = "n", desc = "Add current buffer to Claude" },
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
