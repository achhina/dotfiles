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

function M.trace_last_error()
	local output = {}

	-- Get recent messages
	local messages = vim.api.nvim_exec2("messages", { output = true })
	local lines = vim.split(messages.output, "\n")

	-- Find error-related messages
	local error_lines = {}
	local warning_lines = {}

	for i, line in ipairs(lines) do
		if line:match("Error") or line:match("E%d+:") or line:match("^Error:") then
			table.insert(error_lines, string.format("Line %d: %s", i, line))
		elseif line:match("Warning") or line:match("W%d+:") or line:match("^Warning:") then
			table.insert(warning_lines, string.format("Line %d: %s", i, line))
		end
	end

	-- Get last error details
	local last_error = vim.v.errmsg
	if last_error and last_error ~= "" then
		table.insert(output, "LAST ERROR MESSAGE:")
		table.insert(output, last_error)
		table.insert(output, "")
	end

	-- Exception details
	local exception = vim.v.exception
	if exception and exception ~= "" then
		table.insert(output, "LAST EXCEPTION:")
		table.insert(output, exception)
		table.insert(output, "")
	end

	-- Throwpoint
	local throwpoint = vim.v.throwpoint
	if throwpoint and throwpoint ~= "" then
		table.insert(output, "THROWPOINT:")
		table.insert(output, throwpoint)
		table.insert(output, "")
	end

	-- Recent errors from messages
	if #error_lines > 0 then
		table.insert(output, "RECENT ERRORS FROM MESSAGES:")
		table.insert(output, table.concat(error_lines, "\n"))
		table.insert(output, "")
	end

	-- Recent warnings from messages
	if #warning_lines > 0 then
		table.insert(output, "RECENT WARNINGS FROM MESSAGES:")
		table.insert(output, table.concat(warning_lines, "\n"))
		table.insert(output, "")
	end

	-- Current buffer context
	local buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(buf)
	local filetype = vim.bo[buf].filetype
	local cursor = vim.api.nvim_win_get_cursor(0)

	table.insert(output, "CURRENT CONTEXT:")
	table.insert(output, string.format("Buffer: %s", buf_name ~= "" and buf_name or "[No Name]"))
	table.insert(output, string.format("Filetype: %s", filetype))
	table.insert(output, string.format("Cursor: line %d, col %d", cursor[1], cursor[2]))
	table.insert(output, "")

	-- LSP diagnostics at cursor
	local diagnostics = vim.diagnostic.get(buf, { lnum = cursor[1] - 1 })
	if #diagnostics > 0 then
		table.insert(output, "DIAGNOSTICS AT CURSOR:")
		for _, diag in ipairs(diagnostics) do
			local severity = ({ "ERROR", "WARN", "INFO", "HINT" })[diag.severity]
			table.insert(output, string.format("[%s] %s", severity, diag.message))
		end
		table.insert(output, "")
	end

	if #output == 0 then
		table.insert(output, "No recent errors or context issues found.")
	end

	local log_file = write_to_log(format_section("ERROR TRACE", table.concat(output, "\n")), "trace_last_error")
	return "Error trace complete. Details in " .. log_file
end

function M.inspect_cursor()
	local output = {}

	-- Current position
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = cursor[1]
	local col = cursor[2]

	table.insert(output, string.format("CURSOR POSITION: line %d, col %d", line, col))
	table.insert(output, "")

	-- Buffer info
	local buf = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(buf)
	local filetype = vim.bo[buf].filetype

	table.insert(output, "BUFFER INFO:")
	table.insert(output, string.format("Name: %s", buf_name ~= "" and buf_name or "[No Name]"))
	table.insert(output, string.format("Filetype: %s", filetype))
	table.insert(output, string.format("Buffer ID: %d", buf))
	table.insert(output, "")

	-- Current line content
	local current_line = vim.api.nvim_get_current_line()
	table.insert(output, "CURRENT LINE:")
	table.insert(output, current_line)
	table.insert(output, "")

	-- Character under cursor
	if col < #current_line then
		local char = current_line:sub(col + 1, col + 1)
		table.insert(output, string.format("CHARACTER UNDER CURSOR: '%s' (ASCII: %d)", char, char:byte()))
		table.insert(output, "")
	end

	-- TreeSitter info
	if vim.treesitter.highlighter.active[buf] then
		local ts_info = {}

		-- Get the parser
		local ok, parser = pcall(vim.treesitter.get_parser, buf)
		if ok and parser then
			local trees = parser:parse()
			local tree = trees and trees[1]
			if not tree then
				return nil
			end
			local root = tree:root()

			-- Get node at cursor
			local node = root:descendant_for_range(line - 1, col, line - 1, col)
			if node then
				table.insert(ts_info, string.format("TreeSitter node: %s", node:type()))
				table.insert(ts_info, string.format("Node range: (%d,%d) to (%d,%d)", node:range()))

				-- Get parent nodes
				local parent = node:parent()
				local parents = {}
				while parent do
					table.insert(parents, parent:type())
					parent = parent:parent()
					if #parents > 10 then
						break
					end -- Prevent infinite loops
				end

				if #parents > 0 then
					table.insert(ts_info, "Parent nodes: " .. table.concat(parents, " -> "))
				end
			end
		end

		if #ts_info > 0 then
			table.insert(output, "TREESITTER INFO:")
			table.insert(output, table.concat(ts_info, "\n"))
			table.insert(output, "")
		end
	end

	-- Syntax highlighting
	local synstack = vim.fn.synstack(line, col + 1)
	if #synstack > 0 then
		local syntax_info = {}
		for _, id in ipairs(synstack) do
			local name = vim.fn.synIDattr(id, "name")
			table.insert(syntax_info, name)
		end
		table.insert(output, "SYNTAX STACK:")
		table.insert(output, table.concat(syntax_info, " -> "))
		table.insert(output, "")
	end

	-- LSP info
	local clients = vim.lsp.get_clients({ bufnr = buf })
	if #clients > 0 then
		table.insert(output, "ACTIVE LSP CLIENTS:")
		for _, client in ipairs(clients) do
			table.insert(output, string.format("  %s (id: %d)", client.name, client.id))
		end
		table.insert(output, "")
	end

	-- Diagnostics
	local diagnostics = vim.diagnostic.get(buf, { lnum = line - 1 })
	if #diagnostics > 0 then
		table.insert(output, "DIAGNOSTICS ON LINE:")
		for _, diag in ipairs(diagnostics) do
			local severity = ({ "ERROR", "WARN", "INFO", "HINT" })[diag.severity]
			table.insert(output, string.format("[%s] %s", severity, diag.message))
		end
		table.insert(output, "")
	end

	-- Marks (check for marks on current line)
	local line_marks = {}
	-- Check lowercase marks (a-z) - buffer-local marks
	for i = string.byte("a"), string.byte("z") do
		local mark_char = string.char(i)
		local mark_pos = vim.api.nvim_buf_get_mark(buf, mark_char)
		if mark_pos[1] == line then
			table.insert(line_marks, string.format("'%s", mark_char))
		end
	end

	-- Check uppercase marks (A-Z) - global marks
	for i = string.byte("A"), string.byte("Z") do
		local mark_char = string.char(i)
		local mark_pos = vim.api.nvim_get_mark(mark_char, {})
		if mark_pos[1] == line and mark_pos[4] == vim.api.nvim_buf_get_name(buf) then
			table.insert(line_marks, string.format("'%s", mark_char))
		end
	end

	if #line_marks > 0 then
		table.insert(output, "MARKS ON LINE:")
		table.insert(output, table.concat(line_marks, " "))
		table.insert(output, "")
	end

	local log_file = write_to_log(format_section("CURSOR INSPECTION", table.concat(output, "\n")), "inspect_cursor")
	return "Cursor inspection complete. Details in " .. log_file
end

function M.health_summary()
	local output = {}

	-- Manual health checks for key components (safer than :checkhealth)
	table.insert(output, "COMPONENT STATUS:")

	-- LSP check
	local lsp_clients = vim.lsp.get_clients()
	table.insert(
		output,
		string.format("LSP: %s (%d active clients)", #lsp_clients > 0 and "✓" or "✗", #lsp_clients)
	)

	-- TreeSitter check
	local has_ts = pcall(require, "nvim-treesitter")
	table.insert(output, string.format("TreeSitter: %s", has_ts and "✓" or "✗"))

	-- Lazy check
	local has_lazy = package.loaded["lazy"] ~= nil
	table.insert(output, string.format("Lazy.nvim: %s", has_lazy and "✓" or "✗"))

	-- Mason check
	local has_mason = pcall(require, "mason")
	table.insert(output, string.format("Mason: %s", has_mason and "✓" or "✗"))

	-- Telescope check
	local has_telescope = pcall(require, "telescope")
	table.insert(output, string.format("Telescope: %s", has_telescope and "✓" or "✗"))

	-- Completion check
	local has_cmp = pcall(require, "blink.cmp") or pcall(require, "cmp")
	table.insert(output, string.format("Completion: %s", has_cmp and "✓" or "✗"))

	-- Quick system info
	table.insert(output, "")
	table.insert(output, "SYSTEM INFO:")

	local version = vim.version()
	table.insert(output, string.format("Neovim: %d.%d.%d", version.major, version.minor, version.patch))

	local has_node = vim.fn.executable("node") == 1
	local has_python = vim.fn.executable("python3") == 1
	local has_git = vim.fn.executable("git") == 1

	table.insert(output, string.format("Node.js: %s", has_node and "✓" or "✗"))
	table.insert(output, string.format("Python3: %s", has_python and "✓" or "✗"))
	table.insert(output, string.format("Git: %s", has_git and "✓" or "✗"))

	-- Plugin status
	if package.loaded["lazy"] then
		local lazy = require("lazy")
		local plugins = lazy.plugins()
		local loaded = 0
		local errors = 0

		for _, plugin in ipairs(plugins) do
			if plugin._.loaded then
				loaded = loaded + 1
			end
			---@diagnostic disable-next-line: undefined-field
			if plugin._.error then
				errors = errors + 1
			end
		end

		table.insert(output, "")
		table.insert(output, "PLUGIN STATUS:")
		table.insert(output, string.format("Total plugins: %d", #plugins))
		table.insert(output, string.format("Loaded: %d", loaded))
		table.insert(output, string.format("Errors: %d", errors))
	end

	-- Recent errors
	local messages = vim.api.nvim_exec2("messages", { output = true })
	local error_count = 0
	for line in messages.output:gmatch("[^\r\n]+") do
		if line:match("Error") or line:match("E%d+:") then
			error_count = error_count + 1
		end
	end

	table.insert(output, "")
	table.insert(output, "RECENT ACTIVITY:")
	table.insert(output, string.format("Recent errors: %d", error_count))

	local log_file = write_to_log(format_section("HEALTH SUMMARY", table.concat(output, "\n")), "health_summary")
	return "Health summary complete. Details in " .. log_file
end

return M
