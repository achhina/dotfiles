-- Compatibility layer for deprecated functions
-- This suppresses deprecation warnings from outdated plugins

local M = {}

function M.setup()
	-- Suppress deprecation warnings for known plugin issues
	local original_notify = vim.notify

	vim.notify = function(msg, level, opts)
		-- Filter out all known deprecation warnings from plugins that haven't updated yet
		if type(msg) == "string" and level == vim.log.levels.WARN then
			local deprecated_patterns = {
				"buf_get_clients.*deprecated", -- project.nvim, outline.nvim
				"client%.is_stopped.*deprecated", -- copilot-cmp
				"vim%.lsp%.buf_get_clients.*deprecated", -- project.nvim
				"vim%.tbl_flatten.*deprecated", -- neotest-jest, dial.nvim
				"vim%.validate.*deprecated", -- bigfile.nvim, dial.nvim
			}

			for _, pattern in ipairs(deprecated_patterns) do
				if msg:match(pattern) then
					-- Log at debug level instead of warning to reduce noise
					if vim.log.levels.DEBUG >= (vim.log.level or vim.log.levels.WARN) then
						original_notify(msg, vim.log.levels.DEBUG, opts)
					end
					return
				end
			end
		end

		-- Pass through all other notifications normally
		original_notify(msg, level, opts)
	end

	-- Disable vim.deprecated health check since all warnings are from outdated plugins
	-- This prevents the overwhelming output from :checkhealth vim.deprecated
	local health = require("vim.health")
	if health and health.check then
		local original_check = health.check
		local function wrapped_check(...)
			local args = { ... }
			-- Skip vim.deprecated health check
			if args[1] and args[1]:match("vim%.deprecated") then
				return
			end
			return original_check(...)
		end
		health.check = wrapped_check
	end
end

return M
