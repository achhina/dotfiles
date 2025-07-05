local M = {}

local function_modules = {
	state = {
		capture_state = {
			module = "nvim-debug.functions.state",
			desc = "Capture current Neovim state (messages, buffers, windows, filetypes)",
		},
		capture_config = {
			module = "nvim-debug.functions.state",
			desc = "Capture current configuration and loaded plugins",
		},
		capture_performance = {
			module = "nvim-debug.functions.state",
			desc = "Capture memory usage and performance metrics",
		},
	},
	profile = {
		toggle_profile = { module = "nvim-debug.functions.profile", desc = "Toggle profiling on/off" },
		start_profile = { module = "nvim-debug.functions.profile", desc = "Start profiling with smart defaults" },
		stop_profile = { module = "nvim-debug.functions.profile", desc = "Stop profiling and save results" },
		profile_startup = { module = "nvim-debug.functions.profile", desc = "Profile startup time with restart" },
	},
	conflicts = {
		check_keymaps = { module = "nvim-debug.functions.conflicts", desc = "Find keymap conflicts and overlaps" },
		check_autocmds = { module = "nvim-debug.functions.conflicts", desc = "List and validate autocmd chains" },
	},
	inspect = {
		trace_last_error = { module = "nvim-debug.functions.inspect", desc = "Enhanced error context and stack trace" },
		health_summary = { module = "nvim-debug.functions.inspect", desc = "Condensed health check results" },
	},
	utils = {
		reset_cache = { module = "nvim-debug.functions.utils", desc = "Clear various Neovim caches" },
		backup_session = { module = "nvim-debug.functions.utils", desc = "Save current session state" },
	},
}

local function get_all_functions()
	local all_functions = {}
	for category, functions in pairs(function_modules) do
		for func_name, func_info in pairs(functions) do
			all_functions[func_name] = func_info
		end
	end
	return all_functions
end

local function lazy_load_function(func_name)
	local all_functions = get_all_functions()
	local func_info = all_functions[func_name]

	if not func_info then
		error("Debug function '" .. func_name .. "' not found")
	end

	local ok, module = pcall(require, func_info.module)
	if not ok then
		error("Failed to load debug module: " .. func_info.module)
	end

	local func = module[func_name]
	if not func then
		error("Function '" .. func_name .. "' not found in module " .. func_info.module)
	end

	return func
end

function M.run_debug_function(func_name, ...)
	local func = lazy_load_function(func_name)
	return func(...)
end

function M.get_function_list()
	local all_functions = get_all_functions()
	local function_list = {}
	for func_name, func_info in pairs(all_functions) do
		table.insert(function_list, func_name)
	end
	table.sort(function_list)
	return function_list
end

function M.get_function_description(func_name)
	local all_functions = get_all_functions()
	local func_info = all_functions[func_name]
	return func_info and func_info.desc or "No description available"
end

function M.setup()
	-- Create the :Debug command
	vim.api.nvim_create_user_command("Debug", function(opts)
		local func_name = opts.args
		if func_name == "" then
			print("Available debug functions:")
			for _, name in ipairs(M.get_function_list()) do
				print("  " .. name .. " - " .. M.get_function_description(name))
			end
			return
		end

		local ok, result = pcall(M.run_debug_function, func_name)
		if not ok then
			vim.notify("Debug function failed: " .. result, vim.log.levels.ERROR)
		elseif result then
			vim.notify("Debug function completed: " .. tostring(result), vim.log.levels.INFO)

			-- Extract file path from result and open it
			local file_path = result:match("(/[^%s]*%.log)") or result:match("(/[^%s]*%.txt)")
			if file_path and vim.fn.filereadable(file_path) == 1 then
				vim.schedule(function()
					vim.cmd("edit " .. vim.fn.fnameescape(file_path))
				end)
			end
		end
	end, {
		nargs = "?",
		complete = function(arglead, cmdline, cursorpos)
			return vim.tbl_filter(function(func_name)
				return func_name:match("^" .. arglead)
			end, M.get_function_list())
		end,
		desc = "Run debug functions - use without args to list available functions",
	})

	-- Set up keymaps
	local function map(mode, lhs, rhs, opts)
		opts = opts or {}
		opts.desc = opts.desc or ""
		vim.keymap.set(mode, lhs, rhs, opts)
	end

	-- Helper function to run debug function with auto-open
	local function run_debug_with_autoopen(func_name)
		local ok, result = pcall(M.run_debug_function, func_name)
		if not ok then
			vim.notify("Debug function failed: " .. result, vim.log.levels.ERROR)
		elseif result then
			vim.notify("Debug function completed: " .. tostring(result), vim.log.levels.INFO)

			-- Extract file path from result and open it
			local file_path = result:match("(/[^%s]*%.log)") or result:match("(/[^%s]*%.txt)")
			if file_path and vim.fn.filereadable(file_path) == 1 then
				vim.schedule(function()
					vim.cmd("edit " .. vim.fn.fnameescape(file_path))
				end)
			end
		end
	end

	-- Nvim debug operations (grouped under dC* to avoid DAP conflicts)
	map("n", "<leader>dC", "", { desc = "+nvim-debug" })
	map("n", "<leader>dCs", function()
		run_debug_with_autoopen("capture_state")
	end, { desc = "Debug: Capture state" })
	map("n", "<leader>dCc", function()
		run_debug_with_autoopen("capture_config")
	end, { desc = "Debug: Capture config" })
	map("n", "<leader>dP", function()
		run_debug_with_autoopen("capture_performance")
	end, { desc = "Debug: Capture performance" })
	map("n", "<leader>dp", function()
		run_debug_with_autoopen("toggle_profile")
	end, { desc = "Debug: Toggle profiling" })
	map("n", "<leader>dk", function()
		run_debug_with_autoopen("check_keymaps")
	end, { desc = "Debug: Check keymaps" })
	map("n", "<leader>dCa", function()
		run_debug_with_autoopen("check_autocmds")
	end, { desc = "Debug: Check autocmds" })
	map("n", "<leader>dCh", function()
		run_debug_with_autoopen("health_summary")
	end, { desc = "Debug: Health summary" })
end

return M
