return {
	"rmagatti/auto-session",
	enabled = false, -- Disabled - using persistence.nvim instead to prevent session conflicts

	---@type table
	opts = {
		suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
		-- log_level = 'debug',
		bypass_save_filetypes = { "dashboard" },
	},
}
