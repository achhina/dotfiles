-- Safe module loader with error handling
local function safe_require(module_name, setup_function)
	local ok, module = pcall(require, module_name)
	if not ok then
		vim.notify("Failed to load " .. module_name .. ": " .. module, vim.log.levels.ERROR)
		return false
	end

	if setup_function and type(module[setup_function]) == "function" then
		local setup_ok, setup_err = pcall(module[setup_function])
		if not setup_ok then
			vim.notify(
				"Failed to setup " .. module_name .. "." .. setup_function .. ": " .. setup_err,
				vim.log.levels.ERROR
			)
			return false
		end
	end

	return true
end

-- Load core configuration with error handling
safe_require("config.options", "load_options")
safe_require("config.keymaps", "setup")
safe_require("config.autocmds", "load_autocmds")
