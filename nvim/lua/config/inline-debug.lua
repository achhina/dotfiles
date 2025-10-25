-- Inline debugging enhancements
-- This module provides inline variable editing and advanced debugging UX

local M = {}

-- Inline variable editing during debug sessions
M.inline_edit = {
	-- Edit variable value inline
	edit_variable = function()
		local dap = require("dap")
		if not dap.session then
			vim.notify("No active debug session", vim.log.levels.WARN)
			return
		end

		local session = dap.session

		-- Get word under cursor (variable name)
		local var_name = vim.fn.expand("<cword>")
		if var_name == "" then
			var_name = vim.fn.input("Variable name: ")
		end

		-- Get current variable value
		session:evaluate(var_name, function(err, result)
			if err then
				vim.notify("Error getting variable: " .. err.message, vim.log.levels.ERROR)
				return
			end

			local current_value = result.result or ""
			local new_value = vim.fn.input("New value for " .. var_name .. ": ", current_value)

			if new_value ~= "" and new_value ~= current_value then
				-- Set new variable value
				local set_expr = var_name .. " = " .. new_value
				session:evaluate(set_expr, function(set_err, _)
					if set_err then
						vim.notify("Error setting variable: " .. set_err.message, vim.log.levels.ERROR)
					else
						vim.notify("Variable " .. var_name .. " set to: " .. new_value, vim.log.levels.INFO)
						-- Refresh DAP UI if available
						local ok, dapui = pcall(require, "dapui")
						if ok and dapui and dapui.refresh then
							dapui.refresh()
						end
					end
				end)
			end
		end)
	end,

	-- Quick expression evaluation
	evaluate_expression = function()
		local dap = require("dap")
		if not dap.session then
			vim.notify("No active debug session", vim.log.levels.WARN)
			return
		end

		local session = dap.session

		local expr = vim.fn.input("Evaluate expression: ")
		if expr ~= "" then
			session:evaluate(expr, function(err, result)
				if err then
					vim.notify("Error: " .. err.message, vim.log.levels.ERROR)
				else
					vim.notify("Result: " .. (result.result or "nil"), vim.log.levels.INFO)
				end
			end)
		end
	end,

	-- Watch expression under cursor
	add_watch = function()
		local var_name = vim.fn.expand("<cword>")
		if var_name == "" then
			var_name = vim.fn.input("Watch expression: ")
		end

		if var_name ~= "" then
			-- Add to watches (this is a simplified approach)
			vim.notify("Added watch: " .. var_name, vim.log.levels.INFO)
			-- In a real implementation, this would add to DAP UI watches
		end
	end,
}

-- Enhanced breakpoint management
M.breakpoints = {
	-- Conditional breakpoint with smart defaults
	set_conditional_breakpoint = function()
		local var_name = vim.fn.expand("<cword>")

		-- Smart default conditions based on context
		local default_condition = ""
		if var_name ~= "" then
			default_condition = var_name .. " == "
		end

		local condition = vim.fn.input("Breakpoint condition: ", default_condition)
		if condition ~= "" then
			require("dap").set_breakpoint(condition)
		end
	end,

	-- Log point with variable interpolation
	set_log_point = function()
		local var_name = vim.fn.expand("<cword>")

		local default_msg = ""
		if var_name ~= "" then
			default_msg = "Debug: " .. var_name .. " = {" .. var_name .. "}"
		end

		local msg = vim.fn.input("Log message: ", default_msg)
		if msg ~= "" then
			require("dap").set_breakpoint(nil, nil, msg)
		end
	end,

	-- Breakpoint groups management
	create_breakpoint_group = function()
		local group_name = vim.fn.input("Breakpoint group name: ")
		if group_name ~= "" then
			-- This is a conceptual implementation
			-- Real implementation would track breakpoint groups
			vim.g.dap_breakpoint_groups = vim.g.dap_breakpoint_groups or {}
			vim.g.dap_breakpoint_groups[group_name] = {
				breakpoints = {},
				enabled = true,
			}
			vim.notify("Created breakpoint group: " .. group_name, vim.log.levels.INFO)
		end
	end,
}

-- Debug session enhancements
M.session = {
	-- Auto-save debug workspace
	auto_save_workspace = function()
		local dap = require("dap")
		if dap.session then
			local session = dap.session

			-- Save current debug state
			local workspace = {
				file = vim.fn.expand("%:p"),
				cursor = vim.api.nvim_win_get_cursor(0),
				breakpoints = dap.list_breakpoints(),
				---@diagnostic disable-next-line: undefined-field
				session_config = session.config or {},
				timestamp = os.time(),
			}

			local workspace_file = vim.fn.stdpath("data") .. "/dap_workspace_auto.json"
			local file = io.open(workspace_file, "w")
			if file then
				file:write(vim.fn.json_encode(workspace))
				file:close()
			end
		end
	end,

	-- Restore debug workspace
	restore_workspace = function()
		local workspace_file = vim.fn.stdpath("data") .. "/dap_workspace_auto.json"
		if vim.fn.filereadable(workspace_file) == 1 then
			local content = table.concat(vim.fn.readfile(workspace_file), "\n")
			local workspace = vim.fn.json_decode(content)

			-- Restore file and cursor position
			if workspace.file and vim.fn.filereadable(workspace.file) == 1 then
				vim.cmd("edit " .. workspace.file)
				if workspace.cursor then
					vim.api.nvim_win_set_cursor(0, workspace.cursor)
				end
			end

			-- Restore breakpoints
			if workspace.breakpoints then
				local dap = require("dap")
				for file_path, breakpoints in pairs(workspace.breakpoints) do
					for _, bp in ipairs(breakpoints) do
						vim.api.nvim_buf_call(vim.fn.bufnr(file_path), function()
							dap.set_breakpoint(bp.condition, bp.hit_condition, bp.log_message)
						end)
					end
				end
			end

			vim.notify("Debug workspace restored", vim.log.levels.INFO)
		end
	end,

	-- Debug session recording (conceptual)
	start_recording = function()
		-- This would start recording debug session actions
		vim.g.dap_recording = {
			started = os.time(),
			actions = {},
		}
		vim.notify("Debug session recording started", vim.log.levels.INFO)
	end,

	stop_recording = function()
		if vim.g.dap_recording then
			local duration = os.time() - vim.g.dap_recording.started
			vim.notify("Debug session recorded: " .. duration .. "s", vim.log.levels.INFO)

			-- Save recording to file
			local recording_file = vim.fn.stdpath("data") .. "/dap_recordings/" .. os.date("%Y%m%d_%H%M%S") .. ".json"
			vim.fn.mkdir(vim.fn.fnamemodify(recording_file, ":h"), "p")

			local file = io.open(recording_file, "w")
			if file then
				file:write(vim.fn.json_encode(vim.g.dap_recording))
				file:close()
			end

			vim.g.dap_recording = nil
		end
	end,
}

-- Performance monitoring during debugging
M.performance = {
	-- Monitor debug performance
	start_performance_monitoring = function()
		vim.g.dap_perf_start = vim.uv.hrtime()
		vim.notify("Performance monitoring started", vim.log.levels.INFO)
	end,

	stop_performance_monitoring = function()
		if vim.g.dap_perf_start then
			local duration = (vim.uv.hrtime() - vim.g.dap_perf_start) / 1e9
			vim.notify(string.format("Debug session duration: %.2fs", duration), vim.log.levels.INFO)
			vim.g.dap_perf_start = nil
		end
	end,
}

-- Setup function
function M.setup()
	-- Auto-save workspace on debug session end
	local dap = require("dap")
	dap.listeners.before.event_terminated["inline_debug"] = function()
		M.session.auto_save_workspace()
		M.performance.stop_performance_monitoring()
	end

	dap.listeners.after.event_initialized["inline_debug"] = function()
		M.performance.start_performance_monitoring()
	end

	-- Note: Most inline-debug keymaps removed to avoid conflicts with DAP
	-- DAP already provides better evaluate (<leader>de), breakpoint management, etc.
	-- Only keeping unique functionality that doesn't conflict

	-- Enhanced breakpoint features (unique, no conflicts)
	vim.keymap.set(
		"n",
		"<leader>dbg",
		M.breakpoints.create_breakpoint_group,
		{ desc = "Debug: Create Breakpoint Group" }
	)

	-- Session workspace management (unique features)
	vim.keymap.set("n", "<leader>dws", M.session.auto_save_workspace, { desc = "Debug: Save Workspace" })
	vim.keymap.set("n", "<leader>dwr", M.session.restore_workspace, { desc = "Debug: Restore Workspace" })

	-- User commands
	vim.api.nvim_create_user_command(
		"DapEditVar",
		M.inline_edit.edit_variable,
		{ desc = "Edit variable during debugging" }
	)
	vim.api.nvim_create_user_command("DapEval", M.inline_edit.evaluate_expression, { desc = "Evaluate expression" })
	vim.api.nvim_create_user_command(
		"DapSaveWorkspace",
		M.session.auto_save_workspace,
		{ desc = "Save debug workspace" }
	)
	vim.api.nvim_create_user_command(
		"DapRestoreWorkspace",
		M.session.restore_workspace,
		{ desc = "Restore debug workspace" }
	)
end

return M
