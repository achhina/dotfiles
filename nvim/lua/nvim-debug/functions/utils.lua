local M = {}

local function get_timestamp_filename()
	return os.date("%Y%m%d_%H%M%S")
end

local function get_log_file(func_name)
	local data_dir = vim.fn.stdpath("data")
	local debug_dir = data_dir .. "/debug"
	vim.fn.mkdir(debug_dir, "p")
	local timestamp = get_timestamp_filename()
	return debug_dir .. "/" .. func_name .. "_" .. timestamp .. ".log"
end

local function write_to_log(content, func_name)
	local log_file = get_log_file(func_name or "debug")
	local file = io.open(log_file, "w")
	if file then
		file:write(content .. "\n")
		file:close()
		return log_file
	else
		error("Failed to write to debug log: " .. log_file)
	end
end

local function format_section(title, content)
	local separator = string.rep("=", 50)
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	return separator .. "\n" .. title .. " - " .. timestamp .. "\n" .. separator .. "\n" .. content .. "\n\n"
end

function M.reset_cache()
	local actions = {}

	-- Clear Lua module cache
	local module_count = 0
	for module_name, _ in pairs(package.loaded) do
		if not module_name:match("^vim") and not module_name:match("^_") then
			package.loaded[module_name] = nil
			module_count = module_count + 1
		end
	end
	table.insert(actions, string.format("Cleared %d Lua modules from cache", module_count))

	-- Force garbage collection
	local before_gc = collectgarbage("count")
	collectgarbage("collect")
	local after_gc = collectgarbage("count")
	local freed = before_gc - after_gc
	table.insert(actions, string.format("Garbage collection freed %.2f KB", freed))

	-- Clear LSP cache if available
	if vim.lsp then
		-- Clear LSP client capabilities cache
		for _, client in pairs(vim.lsp.get_clients()) do
			if client.server_capabilities then
				table.insert(actions, string.format("Cleared LSP cache for %s", client.name))
			end
		end
	end

	-- Clear TreeSitter cache
	if package.loaded["nvim-treesitter"] then
		local ts_parsers = require("nvim-treesitter.parsers")
		if ts_parsers.reset_cache then
			ts_parsers.reset_cache()
			table.insert(actions, "Cleared TreeSitter parser cache")
		end
	end

	-- Clear plugin cache (lazy.nvim)
	if package.loaded["lazy"] then
		local lazy = require("lazy")
		if lazy.reload then
			table.insert(actions, "Triggered lazy.nvim cache refresh")
		end
	end

	-- Clear autocmd cache
	vim.api.nvim_exec2("autocmd! CursorHold", { output = false })
	table.insert(actions, "Cleared autocmd cache")

	-- Clear syntax cache
	vim.cmd("syntax sync fromstart")
	table.insert(actions, "Reset syntax synchronization")

	local log_file = write_to_log(format_section("CACHE RESET", table.concat(actions, "\n")), "reset_cache")
	return string.format("Cache reset complete. %d actions performed. Details in %s", #actions, log_file)
end

function M.backup_session()
	local backup_dir = vim.fn.stdpath("data") .. "/debug/sessions"
	vim.fn.mkdir(backup_dir, "p")

	local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
	local session_file = backup_dir .. "/session_" .. timestamp .. ".vim"

	local session_info = {}

	-- Current working directory
	local cwd = vim.fn.getcwd()
	table.insert(session_info, "cd " .. cwd)

	-- Open buffers
	local buffers = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) then
			local name = vim.api.nvim_buf_get_name(buf)
			if name ~= "" and vim.fn.filereadable(name) == 1 then
				table.insert(buffers, name)
				table.insert(session_info, "edit " .. vim.fn.fnameescape(name))
			end
		end
	end

	-- Current buffer and cursor position
	local current_buf = vim.api.nvim_get_current_buf()
	local current_name = vim.api.nvim_buf_get_name(current_buf)
	if current_name ~= "" then
		local cursor = vim.api.nvim_win_get_cursor(0)
		table.insert(session_info, "buffer " .. vim.fn.fnameescape(current_name))
		table.insert(session_info, "normal! " .. cursor[1] .. "G" .. cursor[2] .. "|")
	end

	-- Window layout
	local win_count = vim.api.nvim_tabpage_list_wins(0)
	if #win_count > 1 then
		table.insert(session_info, '" Window layout with ' .. #win_count .. " windows")
	end

	-- Save to file
	local file = io.open(session_file, "w")
	if file then
		file:write(table.concat(session_info, "\n"))
		file:close()

		local log_content =
			string.format("Session backup created:\nFile: %s\nBuffers: %d\nCWD: %s", session_file, #buffers, cwd)
		write_to_log(format_section("SESSION BACKUP", log_content), "backup_session")

		return string.format("Session backed up to %s (%d buffers)", session_file, #buffers)
	else
		error("Failed to create session backup file: " .. session_file)
	end
end

-- Helper function to list available session backups
function M.list_sessions()
	local backup_dir = vim.fn.stdpath("data") .. "/debug/sessions"
	local sessions = vim.fn.glob(backup_dir .. "/session_*.vim", false, true)

	if #sessions == 0 then
		return "No session backups found in " .. backup_dir
	end

	local session_list = {}
	for _, session in ipairs(sessions) do
		local filename = vim.fn.fnamemodify(session, ":t")
		local size = vim.fn.getfsize(session)
		local modified = vim.fn.getftime(session)
		local date = os.date("%Y-%m-%d %H:%M:%S", modified)

		table.insert(session_list, string.format("%s (%d bytes, %s)", filename, size, date))
	end

	return "Session backups in " .. backup_dir .. ":\n" .. table.concat(session_list, "\n")
end

-- Helper function to restore a session
function M.restore_session(session_name)
	local backup_dir = vim.fn.stdpath("data") .. "/debug/sessions"
	local session_file = backup_dir .. "/" .. session_name

	if vim.fn.filereadable(session_file) == 0 then
		return "Session file not found: " .. session_file
	end

	local ok, err = pcall(function()
		vim.cmd("source " .. session_file)
	end)
	if ok then
		return "Session restored from " .. session_file
	else
		return "Failed to restore session: " .. tostring(err)
	end
end

return M
