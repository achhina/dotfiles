return {
	"nanozuki/tabby.nvim",
	event = "VimEnter",
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
		-- Helper to check if buffer should be renamed to "Claude Code"
		-- Example buffer names: term://~/.config//12345:/opt/homebrew/bin/claude
		local function claude_name_for_buf(bufid)
			local ok, bufname = pcall(vim.api.nvim_buf_get_name, bufid)
			if not ok or not bufname then
				return nil
			end
			-- Case-insensitive match for terminal buffers containing "claude"
			if bufname:match("^term://.*[Cc][Ll][Aa][Uu][Dd][Ee]") then
				-- Unicode escape for nf-fa-asterisk (Font Awesome asterisk icon)
				return "\u{f069} Claude Code"
			end
			return nil -- fallback to default
		end

		local buf_name_opt = {
			mode = "unique",
			override = claude_name_for_buf,
		}

		require("tabby").setup({
			preset = "active_wins_at_tail",
			option = {
				nerdfont = true,
				buf_name = buf_name_opt,
				tab_name = {
					override = function(tabid)
						local api = require("tabby.module.api")
						local cur_win = api.get_tab_current_win(tabid)
						local bufid = vim.api.nvim_win_get_buf(cur_win)
						return claude_name_for_buf(bufid)
					end,
				},
			},
		})
	end,
}
