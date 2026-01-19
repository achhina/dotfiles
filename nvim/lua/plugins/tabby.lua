return {
	"nanozuki/tabby.nvim",
	event = "VimEnter",
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
		local function claude_name_for_buf(bufid)
			local ok, bufname = pcall(vim.api.nvim_buf_get_name, bufid)
			if not ok or not bufname then
				return nil
			end
			if bufname:match("^term://.*[Cc][Ll][Aa][Uu][Dd][Ee]") then
				return "\u{f069} Claude Code"
			end
			return nil
		end

		require("tabby.tabline").use_preset("active_wins_at_tail", {
			buf_name = {
				mode = "unique",
				override = claude_name_for_buf,
			},
			tab_name = {
				name_fallback = function()
					return ""
				end,
			},
		})
	end,
}
