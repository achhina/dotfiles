-- Compatibility layer for deprecated LSP functions
-- This suppresses deprecation warnings from outdated plugins

local M = {}

function M.setup()
	-- Suppress deprecation warnings for known plugin issues
	local original_notify = vim.notify

	vim.notify = function(msg, level, opts)
		-- Filter out known deprecation warnings from plugins that haven't updated yet
		if type(msg) == "string" and msg:match("buf_get_clients.*deprecated") then
			-- Log at debug level instead of warning to reduce noise
			if vim.log.levels.DEBUG >= (vim.log.level or vim.log.levels.WARN) then
				original_notify(msg, vim.log.levels.DEBUG, opts)
			end
			return
		end

		-- Pass through all other notifications normally
		original_notify(msg, level, opts)
	end
end

return M
