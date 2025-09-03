return {
	"sindrets/diffview.nvim",
	opts = {
		-- Disable mercurial support since we only use Git
		hg_cmd = { "false" }, -- Set to a command that always fails to disable hg checks
	},
}
