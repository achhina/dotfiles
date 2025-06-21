return {
	"rmagatti/auto-session",
	lazy = false,

	---@type table
	opts = {
		suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
		-- log_level = 'debug',
		bypass_save_filetypes = { "dashboard" },
	},
}
