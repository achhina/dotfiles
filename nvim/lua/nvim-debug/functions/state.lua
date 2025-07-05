local M = {}

local function get_timestamp()
	return os.date("%Y-%m-%d %H:%M:%S")
end

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
	local file = io.open(log_file, "w") -- Use "w" to create new file each time
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
	return separator .. "\n" .. title .. " - " .. get_timestamp() .. "\n" .. separator .. "\n" .. content .. "\n\n"
end

-- Individual section functions
local function get_current_context()
	local cwd = vim.fn.getcwd()
	local current_file = vim.fn.expand("%:p")
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local buf = vim.api.nvim_get_current_buf()
	local line = cursor_pos[1]
	local col = cursor_pos[2]

	local context_info = {}
	table.insert(context_info, string.format("Working Directory: %s", cwd))
	table.insert(
		context_info,
		string.format("Current File: %s", current_file ~= "" and current_file or "[No file open]")
	)
	table.insert(context_info, string.format("Cursor Position: line %d, column %d", line, col))

	-- Add cursor inspection details
	if current_file ~= "" then
		local current_line = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1] or ""
		table.insert(
			context_info,
			string.format("Current Line: %s", current_line ~= "" and current_line or "[empty line]")
		)

		-- Character under cursor
		if col < #current_line then
			local char = current_line:sub(col + 1, col + 1)
			table.insert(context_info, string.format("Character Under Cursor: '%s' (ASCII: %d)", char, char:byte()))
		end

		-- TreeSitter info at cursor
		if vim.treesitter.highlighter.active[buf] then
			local ok, parser = pcall(vim.treesitter.get_parser, buf)
			if ok then
				local tree = parser:parse()[1]
				local root = tree:root()
				local node = root:descendant_for_range(line - 1, col, line - 1, col)
				if node then
					table.insert(context_info, string.format("TreeSitter Node: %s", node:type()))
					local start_row, start_col, end_row, end_col = node:range()
					table.insert(
						context_info,
						string.format("Node Range: (%d,%d) to (%d,%d)", start_row + 1, start_col, end_row + 1, end_col)
					)
				end
			end
		end

		-- Syntax highlighting at cursor
		local synstack = vim.fn.synstack(line, col + 1)
		if #synstack > 0 then
			local syntax_groups = {}
			for _, id in ipairs(synstack) do
				local name = vim.fn.synIDattr(id, "name")
				if name ~= "" then
					table.insert(syntax_groups, name)
				end
			end
			if #syntax_groups > 0 then
				table.insert(context_info, string.format("Syntax Groups: %s", table.concat(syntax_groups, " -> ")))
			end
		end

		-- Diagnostics at cursor
		local diagnostics = vim.diagnostic.get(buf, { lnum = line - 1 })
		if #diagnostics > 0 then
			local diag_info = {}
			for _, diag in ipairs(diagnostics) do
				local severity = ({ "ERROR", "WARN", "INFO", "HINT" })[diag.severity]
				table.insert(diag_info, string.format("[%s] %s", severity, diag.message))
			end
			table.insert(context_info, "Diagnostics: " .. table.concat(diag_info, "; "))
		end

		-- Marks on current line
		local line_marks = {}
		-- Buffer-local marks (a-z)
		for i = string.byte("a"), string.byte("z") do
			local mark_char = string.char(i)
			local mark_pos = vim.api.nvim_buf_get_mark(buf, mark_char)
			if mark_pos[1] == line then
				table.insert(line_marks, string.format("'%s", mark_char))
			end
		end
		-- Global marks (A-Z)
		for i = string.byte("A"), string.byte("Z") do
			local mark_char = string.char(i)
			local mark_pos = vim.api.nvim_get_mark(mark_char, {})
			if mark_pos[1] == line and mark_pos[4] == vim.api.nvim_buf_get_name(buf) then
				table.insert(line_marks, string.format("'%s", mark_char))
			end
		end
		if #line_marks > 0 then
			table.insert(context_info, string.format("Marks on Line: %s", table.concat(line_marks, " ")))
		end
	end

	return format_section("CURRENT CONTEXT", table.concat(context_info, "\n"))
end

local function get_open_buffers()
	local buffers = {}
	table.insert(buffers, "Format: Buffer ID: filename [filetype] (line count) [modified status]")
	table.insert(buffers, "")
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) then
			local name = vim.api.nvim_buf_get_name(buf)
			local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
			local modified = vim.api.nvim_buf_get_option(buf, "modified")
			local lines = vim.api.nvim_buf_line_count(buf)

			local display_name = name ~= "" and vim.fn.fnamemodify(name, ":~") or "[Unnamed Buffer]"
			local file_type = filetype ~= "" and filetype or "no filetype"
			local mod_status = modified and " (modified)" or ""

			table.insert(
				buffers,
				string.format("Buffer %d: %s [%s] (%d lines)%s", buf, display_name, file_type, lines, mod_status)
			)
		end
	end
	return format_section("OPEN BUFFERS", table.concat(buffers, "\n"))
end

local function get_open_windows()
	local windows = {}
	table.insert(windows, "Format: Window ID: filename [filetype] (width by height) [current indicator]")
	table.insert(windows, "")
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local name = vim.api.nvim_buf_get_name(buf)
		local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
		local width = vim.api.nvim_win_get_width(win)
		local height = vim.api.nvim_win_get_height(win)

		local display_name = name ~= "" and vim.fn.fnamemodify(name, ":t") or "[Unnamed]"
		local file_type = filetype ~= "" and filetype or "no filetype"
		local is_current = win == vim.api.nvim_get_current_win() and " (current)" or ""

		table.insert(
			windows,
			string.format("Window %d: %s [%s] (%d by %d)%s", win, display_name, file_type, width, height, is_current)
		)
	end
	return format_section("OPEN WINDOWS", table.concat(windows, "\n"))
end

local function get_lsp_clients()
	local lsp_info = {}
	local clients = vim.lsp.get_active_clients()
	if #clients > 0 then
		table.insert(lsp_info, string.format("Active LSP clients: %d", #clients))
		table.insert(lsp_info, "")
		for _, client in ipairs(clients) do
			local attached_buffers = {}
			for _, buf in ipairs(vim.lsp.get_buffers_by_client_id(client.id)) do
				table.insert(attached_buffers, buf)
			end
			table.insert(lsp_info, string.format("Client: %s (id: %d)", client.name, client.id))
			table.insert(lsp_info, string.format("  Attached to buffers: %s", table.concat(attached_buffers, ", ")))
			table.insert(lsp_info, string.format("  Root dir: %s", client.config.root_dir or "not set"))
		end
	else
		table.insert(lsp_info, "No active LSP clients")
	end
	return format_section("ACTIVE LSP CLIENTS", table.concat(lsp_info, "\n"))
end

local function get_tabs_and_layout()
	local tab_info = {}
	local current_tab = vim.api.nvim_get_current_tabpage()
	local tabs = vim.api.nvim_list_tabpages()
	table.insert(tab_info, string.format("Current tab: %d of %d", current_tab, #tabs))

	for i, tab in ipairs(tabs) do
		local tab_wins = vim.api.nvim_tabpage_list_wins(tab)
		local is_current = tab == current_tab and " (current)" or ""
		table.insert(tab_info, string.format("Tab %d: %d windows%s", tab, #tab_wins, is_current))
	end

	-- Window layout analysis
	local floating_wins = 0
	local split_wins = 0
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local config = vim.api.nvim_win_get_config(win)
		if config.relative ~= "" then
			floating_wins = floating_wins + 1
		else
			split_wins = split_wins + 1
		end
	end
	table.insert(tab_info, string.format("Layout: %d split windows, %d floating windows", split_wins, floating_wins))
	return format_section("TABS & LAYOUT", table.concat(tab_info, "\n"))
end

local function get_plugin_status()
	local plugin_info = {}

	-- Check if lazy.nvim is available
	if not package.loaded["lazy"] then
		table.insert(plugin_info, "lazy.nvim not detected")
		return format_section("PLUGIN STATUS", table.concat(plugin_info, "\n"))
	end

	local lazy = require("lazy")

	-- Get lazy's status report
	local stats = lazy.stats()
	table.insert(plugin_info, string.format("Plugin Manager: lazy.nvim"))
	table.insert(plugin_info, string.format("Total plugins: %d", stats.count))
	table.insert(plugin_info, string.format("Currently loaded: %d", stats.loaded))
	table.insert(plugin_info, string.format("Startup time: %.2f ms", stats.startuptime))
	table.insert(plugin_info, "")

	-- Quick health status
	local plugins = lazy.plugins()
	local failed_plugins = {}
	local slow_plugins = {}
	local total_errors = 0
	local missing_deps = 0

	for _, plugin in ipairs(plugins) do
		-- Check for errors
		if plugin._.error then
			total_errors = total_errors + 1
			table.insert(failed_plugins, {
				name = plugin.name,
				error = plugin._.error,
			})
		end

		-- Check for slow loading
		if plugin._.stats and plugin._.stats.loaded then
			local load_time = plugin._.stats.loaded.time or 0
			if load_time > 50 then -- >50ms is notable
				table.insert(slow_plugins, {
					name = plugin.name,
					time = load_time,
				})
			end
		end

		-- Check dependencies
		if plugin.dependencies then
			for _, dep in ipairs(plugin.dependencies) do
				local dep_name = type(dep) == "string" and dep or (dep.name or dep[1])
				if dep_name then
					local found = false
					for _, other_plugin in ipairs(plugins) do
						if other_plugin.name == dep_name or other_plugin[1] == dep_name then
							found = true
							break
						end
					end
					if not found then
						missing_deps = missing_deps + 1
					end
				end
			end
		end
	end

	-- Health summary
	if total_errors == 0 then
		table.insert(plugin_info, "✓ No plugin loading errors")
	else
		table.insert(plugin_info, string.format("✗ %d plugins have loading errors", total_errors))
	end

	if missing_deps == 0 then
		table.insert(plugin_info, "✓ All plugin dependencies satisfied")
	else
		table.insert(plugin_info, string.format("✗ %d missing plugin dependencies", missing_deps))
	end

	if #slow_plugins == 0 then
		table.insert(plugin_info, "✓ No slow loading plugins detected")
	else
		table.insert(plugin_info, string.format("⚠️  %d plugins loading slowly (>50ms)", #slow_plugins))
	end

	-- Show critical issues if any
	if #failed_plugins > 0 then
		table.insert(plugin_info, "")
		table.insert(plugin_info, "Failed plugins:")
		for i, plugin in ipairs(failed_plugins) do
			if i <= 3 then
				table.insert(plugin_info, string.format("  ✗ %s: %s", plugin.name, plugin.error))
			elseif i == 4 then
				table.insert(plugin_info, string.format("  ... and %d more failures", #failed_plugins - 3))
				break
			end
		end
	end

	if #slow_plugins > 0 then
		table.insert(plugin_info, "")
		table.insert(plugin_info, "Slow loading plugins:")
		table.sort(slow_plugins, function(a, b)
			return a.time > b.time
		end)
		for i, plugin in ipairs(slow_plugins) do
			if i <= 3 then
				table.insert(plugin_info, string.format("  🐌 %s: %.1f ms", plugin.name, plugin.time))
			elseif i == 4 then
				table.insert(plugin_info, string.format("  ... and %d more slow plugins", #slow_plugins - 3))
				break
			end
		end
	end

	return format_section("PLUGIN STATUS", table.concat(plugin_info, "\n"))
end

function M.capture_state()
	local state_info = {}

	-- Use individual functions for each section
	table.insert(state_info, get_current_context())
	table.insert(state_info, get_open_buffers())
	table.insert(state_info, get_open_windows())
	table.insert(state_info, get_lsp_clients())
	table.insert(state_info, get_tabs_and_layout())
	table.insert(state_info, get_plugin_status())

	-- Search and navigation state
	local nav_info = {}
	local search_pattern = vim.fn.getreg("/")
	if search_pattern and search_pattern ~= "" then
		table.insert(nav_info, string.format("Last search: %s", search_pattern))
	else
		table.insert(nav_info, "Last search: none")
	end

	-- Jump list info
	local jumplist = vim.fn.getjumplist()
	if jumplist[1] and #jumplist[1] > 0 then
		table.insert(nav_info, string.format("Jump list: %d entries, position %d", #jumplist[1], jumplist[2] + 1))
	else
		table.insert(nav_info, "Jump list: empty")
	end

	-- Global marks
	local marks = vim.api.nvim_get_mark("A", {})
	local global_marks = {}
	for i = string.byte("A"), string.byte("Z") do
		local mark_char = string.char(i)
		local mark_pos = vim.api.nvim_get_mark(mark_char, {})
		if mark_pos[1] ~= 0 then
			table.insert(global_marks, mark_char)
		end
	end
	if #global_marks > 0 then
		table.insert(nav_info, string.format("Global marks: %s", table.concat(global_marks, ", ")))
	else
		table.insert(nav_info, "Global marks: none")
	end
	table.insert(state_info, format_section("SEARCH & NAVIGATION", table.concat(nav_info, "\n")))

	-- Mode and selection state
	local mode_info = {}
	local current_mode = vim.api.nvim_get_mode()
	table.insert(mode_info, string.format("Current mode: %s", current_mode.mode))
	if current_mode.blocking then
		table.insert(mode_info, "Status: blocking")
	end

	-- Visual selection info
	if current_mode.mode:match("^[vVs]") then
		local start_pos = vim.fn.getpos("'<")
		local end_pos = vim.fn.getpos("'>")
		table.insert(
			mode_info,
			string.format(
				"Selection: line %d col %d to line %d col %d",
				start_pos[2],
				start_pos[3],
				end_pos[2],
				end_pos[3]
			)
		)
	end

	-- Register contents (unnamed and last yank)
	local function sanitize_register_content(content)
		if not content or #content == 0 then
			return "empty"
		end

		-- Replace problematic characters
		local sanitized = content
			:gsub("\n", " ") -- Replace newlines with spaces
			:gsub("\r", " ") -- Replace carriage returns
			:gsub("\t", " ") -- Replace tabs with spaces
			:gsub("%s+", " ") -- Collapse multiple spaces
			:gsub("^%s+", "") -- Trim leading spaces
			:gsub("%s+$", "") -- Trim trailing spaces

		-- Truncate and add ellipsis
		if #sanitized > 50 then
			sanitized = sanitized:sub(1, 47) .. "..."
		end

		return sanitized
	end

	local unnamed_reg = vim.fn.getreg('"')
	local unnamed_preview = sanitize_register_content(unnamed_reg)
	table.insert(mode_info, string.format("Unnamed register: %s", unnamed_preview))

	local yank_reg = vim.fn.getreg("0")
	if yank_reg and #yank_reg > 0 and yank_reg ~= unnamed_reg then
		local yank_preview = sanitize_register_content(yank_reg)
		table.insert(mode_info, string.format("Last yank register: %s", yank_preview))
	end
	table.insert(state_info, format_section("MODE & SELECTION", table.concat(mode_info, "\n")))

	-- Recent file activity
	local recent_info = {}

	-- Files with unsaved changes
	local modified_buffers = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "modified") then
			local name = vim.api.nvim_buf_get_name(buf)
			local display_name = name ~= "" and vim.fn.fnamemodify(name, ":~") or "[Unnamed Buffer]"
			table.insert(modified_buffers, display_name)
		end
	end

	if #modified_buffers > 0 then
		table.insert(recent_info, string.format("Files with unsaved changes: %d", #modified_buffers))
		for i, name in ipairs(modified_buffers) do
			if i <= 5 then -- Show max 5 files
				table.insert(recent_info, string.format("  %s", name))
			elseif i == 6 then
				table.insert(recent_info, string.format("  ... and %d more", #modified_buffers - 5))
				break
			end
		end
	else
		table.insert(recent_info, "Files with unsaved changes: none")
	end

	-- Most recently accessed files (from jumplist)
	local jumplist = vim.fn.getjumplist()
	if jumplist[1] and #jumplist[1] > 0 then
		table.insert(recent_info, "")
		table.insert(recent_info, "Recent files from jumplist:")
		local seen_files = {}
		local file_count = 0

		-- Walk backwards through jumplist to get most recent first
		for i = #jumplist[1], 1, -1 do
			local jump = jumplist[1][i]
			if jump.bufnr and vim.api.nvim_buf_is_valid(jump.bufnr) then
				local name = vim.api.nvim_buf_get_name(jump.bufnr)
				if name ~= "" and not seen_files[name] then
					seen_files[name] = true
					file_count = file_count + 1
					if file_count <= 5 then
						local display_name = vim.fn.fnamemodify(name, ":~")
						table.insert(recent_info, string.format("  %s (line %d)", display_name, jump.lnum))
					else
						break
					end
				end
			end
		end
	end

	-- Recently opened files (oldfiles)
	local oldfiles = vim.v.oldfiles
	if oldfiles and #oldfiles > 0 then
		table.insert(recent_info, "")
		table.insert(recent_info, "Recently opened files:")
		for i = 1, math.min(5, #oldfiles) do
			local file = oldfiles[i]
			if vim.fn.filereadable(file) == 1 then
				local display_name = vim.fn.fnamemodify(file, ":~")
				table.insert(recent_info, string.format("  %s", display_name))
			end
		end
	end

	table.insert(state_info, format_section("RECENT FILE ACTIVITY", table.concat(recent_info, "\n")))

	-- Active key binding conflicts (current context)
	local keymap_info = {}
	local current_mode = vim.api.nvim_get_mode()
	local mode = current_mode.mode
	local buf = vim.api.nvim_get_current_buf()
	local filetype = vim.api.nvim_buf_get_option(buf, "filetype")

	-- Get leader key
	local leader = vim.g.mapleader or "\\"

	-- Helper function to format key display
	local function format_key(key)
		if key:sub(1, 1) == leader then
			return "<leader>" .. key:sub(2)
		end
		return "'" .. key .. "'"
	end

	table.insert(
		keymap_info,
		string.format("Active for mode '%s' and filetype '%s':", mode, filetype ~= "" and filetype or "none")
	)
	table.insert(keymap_info, "")

	-- Get keymaps for current mode
	local mode_keymaps = vim.api.nvim_get_keymap(mode)
	local buffer_keymaps = vim.api.nvim_buf_get_keymap(buf, mode)

	-- Check for conflicts between global and buffer-local keymaps
	local conflicts = {}
	local global_keys = {}

	for _, keymap in ipairs(mode_keymaps) do
		global_keys[keymap.lhs] = keymap
	end

	for _, keymap in ipairs(buffer_keymaps) do
		if global_keys[keymap.lhs] then
			table.insert(conflicts, {
				key = keymap.lhs,
				global = global_keys[keymap.lhs],
				buffer = keymap,
			})
		end
	end

	if #conflicts > 0 then
		table.insert(keymap_info, string.format("Keymap conflicts detected: %d", #conflicts))
		table.insert(keymap_info, "")

		-- Table column widths
		local key_width = 16
		local buffer_desc_width = 24
		local global_desc_width = 26

		-- Create table borders
		local function create_border(left, sep, right, corners)
			local key_line = string.rep("─", key_width + 2)
			local buffer_line = string.rep("─", buffer_desc_width + 2)
			local global_line = string.rep("─", global_desc_width + 2)
			return corners[1] .. key_line .. corners[2] .. buffer_line .. corners[3] .. global_line .. corners[4]
		end

		-- Create a table header
		table.insert(keymap_info, create_border("", "", "", { "┌", "┬", "┬", "┐" }))
		table.insert(
			keymap_info,
			string.format(
				"│ %-" .. key_width .. "s │ %-" .. buffer_desc_width .. "s │ %-" .. global_desc_width .. "s │",
				"Key",
				"Buffer Description",
				"Global Description"
			)
		)
		table.insert(keymap_info, create_border("", "", "", { "├", "┼", "┼", "┤" }))

		for _, conflict in ipairs(conflicts) do
			local key_display = format_key(conflict.key)
			local buffer_desc = conflict.buffer.desc or "no description"
			local global_desc = conflict.global.desc or "no description"

			-- Truncate descriptions to fit table
			if #buffer_desc > buffer_desc_width then
				buffer_desc = buffer_desc:sub(1, buffer_desc_width - 3) .. "..."
			end
			if #global_desc > global_desc_width then
				global_desc = global_desc:sub(1, global_desc_width - 3) .. "..."
			end

			table.insert(
				keymap_info,
				string.format(
					"│ %-"
						.. key_width
						.. "s │ %-"
						.. buffer_desc_width
						.. "s │ %-"
						.. global_desc_width
						.. "s │",
					key_display,
					buffer_desc,
					global_desc
				)
			)
		end

		table.insert(keymap_info, create_border("", "", "", { "└", "┴", "┴", "┘" }))
	else
		table.insert(keymap_info, "No keymap conflicts in current context")
	end

	-- Show buffer-local keymaps in table format
	table.insert(keymap_info, "")
	table.insert(keymap_info, "Buffer-local keymaps:")
	if #buffer_keymaps > 0 then
		table.insert(keymap_info, "")

		-- Table column widths for buffer keymaps
		local buf_key_width = 16
		local buf_desc_width = 46

		-- Create table borders for buffer keymaps
		local function create_buffer_border(corners)
			local key_line = string.rep("─", buf_key_width + 2)
			local desc_line = string.rep("─", buf_desc_width + 2)
			return corners[1] .. key_line .. corners[2] .. desc_line .. corners[3]
		end

		table.insert(keymap_info, create_buffer_border({ "┌", "┬", "┐" }))
		table.insert(
			keymap_info,
			string.format("│ %-" .. buf_key_width .. "s │ %-" .. buf_desc_width .. "s │", "Key", "Description")
		)
		table.insert(keymap_info, create_buffer_border({ "├", "┼", "┤" }))

		for _, keymap in ipairs(buffer_keymaps) do
			local key_display = format_key(keymap.lhs)
			local desc = keymap.desc or "no description"

			-- Truncate description to fit table
			if #desc > buf_desc_width then
				desc = desc:sub(1, buf_desc_width - 3) .. "..."
			end

			table.insert(
				keymap_info,
				string.format("│ %-" .. buf_key_width .. "s │ %-" .. buf_desc_width .. "s │", key_display, desc)
			)
		end

		table.insert(keymap_info, create_buffer_border({ "└", "┴", "┘" }))
		table.insert(keymap_info, string.format("Total buffer-local keymaps: %d", #buffer_keymaps))
	else
		table.insert(keymap_info, "  none")
	end

	table.insert(state_info, format_section("ACTIVE KEYMAPS & CONFLICTS", table.concat(keymap_info, "\n")))

	-- Messages (moved to end because they can be long)
	local messages = vim.api.nvim_exec2("messages", { output = true })
	table.insert(state_info, format_section("MESSAGES", messages.output))

	local log_file = write_to_log(table.concat(state_info, ""), "capture_state")
	return "State captured to " .. log_file
end

function M.capture_config()
	local config_info = {}

	-- Neovim version and build info
	local version_info = vim.version()
	local version_str = string.format("Neovim %d.%d.%d", version_info.major, version_info.minor, version_info.patch)
	if version_info.prerelease then
		version_str = version_str .. "-" .. version_info.prerelease
	end
	table.insert(config_info, format_section("NEOVIM VERSION", version_str))

	-- Important global options
	local global_opts = {
		"runtimepath",
		"packpath",
		"shell",
		"encoding",
		"background",
	}
	local options = {}
	for _, opt in ipairs(global_opts) do
		local ok, value = pcall(vim.api.nvim_get_option, opt)
		if ok then
			table.insert(options, string.format("%s = %s", opt, vim.inspect(value)))
		else
			table.insert(options, string.format("%s = <error getting option>", opt))
		end
	end

	-- Get colorscheme safely
	local colorscheme = vim.g.colors_name or "default"
	table.insert(options, string.format("colorscheme = %s", colorscheme))
	table.insert(config_info, format_section("IMPORTANT OPTIONS", table.concat(options, "\n")))

	-- Plugin configuration (static setup info)
	local plugins = {}
	if package.loaded["lazy"] then
		local lazy_plugins = require("lazy").plugins()
		local loaded_count = 0
		local total_count = #lazy_plugins

		for _, plugin in ipairs(lazy_plugins) do
			if plugin._.loaded then
				loaded_count = loaded_count + 1
			end
		end

		table.insert(plugins, string.format("Plugin manager: lazy.nvim"))
		table.insert(plugins, string.format("Total configured plugins: %d", total_count))
		table.insert(plugins, string.format("Currently loaded: %d", loaded_count))
		table.insert(plugins, string.format("Lazy-loaded: %d", total_count - loaded_count))
	else
		table.insert(plugins, "Plugin manager: not detected")
	end
	table.insert(config_info, format_section("PLUGIN CONFIGURATION", table.concat(plugins, "\n")))

	-- Environment variables
	local env_vars = {
		"NVIM_APPNAME",
		"XDG_CONFIG_HOME",
		"XDG_DATA_HOME",
		"XDG_STATE_HOME",
		"PATH",
		"SHELL",
		"TERM",
		"COLORTERM",
	}
	local env_info = {}
	for _, var in ipairs(env_vars) do
		local value = vim.env[var]
		if value then
			table.insert(env_info, string.format("%s = %s", var, value))
		end
	end
	table.insert(config_info, format_section("ENVIRONMENT", table.concat(env_info, "\n")))

	-- Global variables
	local globals = {}
	for name, value in pairs(vim.g) do
		if type(value) ~= "function" then
			table.insert(globals, string.format("g:%s = %s", name, vim.inspect(value)))
		end
	end
	table.insert(config_info, format_section("GLOBAL VARIABLES", table.concat(globals, "\n")))

	-- Editor settings (moved from capture_state - these are configuration, not runtime state)
	local settings_info = {}

	-- Current colorscheme
	local colorscheme = vim.g.colors_name or "default"
	table.insert(settings_info, string.format("Colorscheme: %s", colorscheme))

	-- Global settings
	local global_settings = {
		{ "hlsearch", "highlight search" },
		{ "ignorecase", "ignore case in search" },
		{ "smartcase", "smart case in search" },
	}

	for _, setting in ipairs(global_settings) do
		local opt, desc = setting[1], setting[2]
		local ok, value = pcall(vim.api.nvim_get_option, opt)
		if ok then
			table.insert(settings_info, string.format("%s: %s", desc, tostring(value)))
		end
	end

	-- Window-local settings (current window)
	local win = vim.api.nvim_get_current_win()
	local window_settings = {
		{ "number", "line numbers" },
		{ "relativenumber", "relative line numbers" },
		{ "wrap", "line wrapping" },
	}

	for _, setting in ipairs(window_settings) do
		local opt, desc = setting[1], setting[2]
		local ok, value = pcall(vim.api.nvim_win_get_option, win, opt)
		if ok then
			table.insert(settings_info, string.format("%s: %s", desc, tostring(value)))
		end
	end

	-- Current buffer specific settings that might differ
	local buf = vim.api.nvim_get_current_buf()
	local buf_settings = {
		{ "expandtab", "expand tabs to spaces" },
		{ "tabstop", "tab width" },
		{ "shiftwidth", "indent width" },
		{ "softtabstop", "soft tab width" },
	}

	table.insert(settings_info, "")
	table.insert(settings_info, "Current buffer settings:")
	for _, setting in ipairs(buf_settings) do
		local opt, desc = setting[1], setting[2]
		local ok, value = pcall(vim.api.nvim_buf_get_option, buf, opt)
		if ok then
			if type(value) == "number" then
				table.insert(settings_info, string.format("  %s: %d", desc, value))
			else
				table.insert(settings_info, string.format("  %s: %s", desc, tostring(value)))
			end
		end
	end
	table.insert(config_info, format_section("EDITOR SETTINGS", table.concat(settings_info, "\n")))

	-- Project and git configuration (moved from capture_state - this is setup info)
	local project_info = {}

	-- Check if we're in a git repository
	local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
	if vim.v.shell_error == 0 then
		local git_branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
		local git_status = vim.fn.system("git status --porcelain 2>/dev/null")
		local changes_count = #vim.split(git_status:gsub("^%s*$", ""), "\n") - 1

		table.insert(project_info, string.format("Git repository: %s", git_root))
		table.insert(project_info, string.format("Current branch: %s", git_branch ~= "" and git_branch or "unknown"))
		table.insert(
			project_info,
			string.format("Uncommitted changes: %d files", changes_count > 0 and changes_count or 0)
		)
	else
		table.insert(project_info, "Git repository: not in a git repository")
	end

	-- Session info
	local session_file = vim.v.this_session
	if session_file and session_file ~= "" then
		table.insert(project_info, string.format("Session file: %s", session_file))
	else
		table.insert(project_info, "Session file: none")
	end

	-- Project root detection (common patterns)
	local project_markers = { ".git", "package.json", "Cargo.toml", "go.mod", "pyproject.toml", "Makefile" }
	local project_root = nil
	local current_dir = vim.fn.getcwd()

	for _, marker in ipairs(project_markers) do
		local marker_path = vim.fn.finddir(marker, current_dir .. ";")
		if marker_path == "" then
			marker_path = vim.fn.findfile(marker, current_dir .. ";")
		end
		if marker_path ~= "" then
			project_root = vim.fn.fnamemodify(marker_path, ":h")
			table.insert(project_info, string.format("Project root: %s (detected via %s)", project_root, marker))
			break
		end
	end

	if not project_root then
		table.insert(project_info, "Project root: not detected")
	end
	table.insert(config_info, format_section("PROJECT & GIT SETUP", table.concat(project_info, "\n")))

	-- Plugin loading issues and status
	local plugin_issues = {}
	if package.loaded["lazy"] then
		local lazy = require("lazy")
		local plugins = lazy.plugins()
		local failed_plugins = {}
		local slow_plugins = {}
		local total_load_time = 0

		for _, plugin in ipairs(plugins) do
			-- Check for loading errors
			if plugin._.error then
				table.insert(failed_plugins, {
					name = plugin.name,
					error = plugin._.error,
				})
			end

			-- Check for slow loading plugins
			if plugin._.stats and plugin._.stats.loaded and plugin._.stats.loaded.time then
				local load_time = plugin._.stats.loaded.time
				total_load_time = total_load_time + load_time
				if load_time > 100 then -- >100ms is considered slow
					table.insert(slow_plugins, {
						name = plugin.name,
						time = load_time,
					})
				end
			end
		end

		-- Sort slow plugins by time
		table.sort(slow_plugins, function(a, b)
			return a.time > b.time
		end)

		table.insert(plugin_issues, string.format("Total plugins: %d", #plugins))
		table.insert(plugin_issues, string.format("Total load time: %.1f ms", total_load_time))

		if #failed_plugins > 0 then
			table.insert(plugin_issues, "")
			table.insert(plugin_issues, string.format("Failed to load: %d plugins", #failed_plugins))
			for i, plugin in ipairs(failed_plugins) do
				if i <= 3 then
					table.insert(plugin_issues, string.format("  %s: %s", plugin.name, plugin.error))
				elseif i == 4 then
					table.insert(plugin_issues, string.format("  ... and %d more failures", #failed_plugins - 3))
					break
				end
			end
		else
			table.insert(plugin_issues, "")
			table.insert(plugin_issues, "Plugin loading: no failures detected")
		end

		if #slow_plugins > 0 then
			table.insert(plugin_issues, "")
			table.insert(plugin_issues, string.format("Slow loading plugins (>100ms): %d", #slow_plugins))
			for i, plugin in ipairs(slow_plugins) do
				if i <= 5 then
					table.insert(plugin_issues, string.format("  %s: %.1f ms", plugin.name, plugin.time))
				elseif i == 6 then
					table.insert(plugin_issues, string.format("  ... and %d more slow plugins", #slow_plugins - 5))
					break
				end
			end
		else
			table.insert(plugin_issues, "")
			table.insert(plugin_issues, "Plugin performance: no slow loading detected")
		end

		-- Check for dependency conflicts (basic check)
		local dependency_issues = {}
		for _, plugin in ipairs(plugins) do
			if plugin.dependencies then
				for _, dep in ipairs(plugin.dependencies) do
					local dep_name = type(dep) == "string" and dep or dep.name or dep[1]
					local found = false
					for _, other_plugin in ipairs(plugins) do
						if other_plugin.name == dep_name then
							found = true
							break
						end
					end
					if not found then
						table.insert(dependency_issues, string.format("%s requires missing %s", plugin.name, dep_name))
					end
				end
			end
		end

		if #dependency_issues > 0 then
			table.insert(plugin_issues, "")
			table.insert(plugin_issues, string.format("Dependency issues: %d", #dependency_issues))
			for i, issue in ipairs(dependency_issues) do
				if i <= 3 then
					table.insert(plugin_issues, string.format("  %s", issue))
				elseif i == 4 then
					table.insert(
						plugin_issues,
						string.format("  ... and %d more dependency issues", #dependency_issues - 3)
					)
					break
				end
			end
		end
	else
		table.insert(plugin_issues, "Plugin manager: not detected")
	end
	table.insert(config_info, format_section("PLUGIN LOADING ANALYSIS", table.concat(plugin_issues, "\n")))

	-- TreeSitter parser status
	local ts_info = {}
	if package.loaded["nvim-treesitter"] then
		local ts_parsers = require("nvim-treesitter.parsers")
		local ts_configs = require("nvim-treesitter.configs")
		local parser_configs = ts_parsers.get_parser_configs()

		local installed = {}
		local missing = {}
		local broken = {}

		for lang, _ in pairs(parser_configs) do
			if ts_parsers.has_parser(lang) then
				table.insert(installed, lang)

				-- Basic health check for parser
				local ok, parser = pcall(ts_parsers.get_parser, 0, lang)
				if not ok then
					table.insert(broken, lang)
				end
			else
				table.insert(missing, lang)
			end
		end

		table.insert(ts_info, string.format("TreeSitter parsers: %d installed, %d missing", #installed, #missing))

		if #broken > 0 then
			table.insert(ts_info, string.format("Broken parsers: %d", #broken))
			for i, lang in ipairs(broken) do
				if i <= 5 then
					table.insert(ts_info, string.format("  %s", lang))
				elseif i == 6 then
					table.insert(ts_info, string.format("  ... and %d more broken parsers", #broken - 5))
					break
				end
			end
		end

		-- Check current buffer parser
		local buf = vim.api.nvim_get_current_buf()
		local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
		if filetype ~= "" then
			table.insert(ts_info, "")
			if ts_parsers.has_parser(filetype) then
				table.insert(ts_info, string.format("Current buffer (%s): parser available", filetype))

				-- Test parser on current buffer
				local ok, parser = pcall(ts_parsers.get_parser, buf, filetype)
				if ok then
					local trees = parser:parse()
					if trees and #trees > 0 then
						table.insert(ts_info, string.format("  Parser status: working (%d syntax trees)", #trees))
					else
						table.insert(ts_info, "  Parser status: no syntax trees generated")
					end
				else
					table.insert(ts_info, "  Parser status: failed to create parser")
				end
			else
				table.insert(ts_info, string.format("Current buffer (%s): no parser available", filetype))
			end
		end
	else
		table.insert(ts_info, "TreeSitter: not installed")
	end
	table.insert(config_info, format_section("TREESITTER STATUS", table.concat(ts_info, "\n")))

	local log_file = write_to_log(table.concat(config_info, ""), "capture_config")
	return "Config captured to " .. log_file
end

function M.capture_performance()
	local perf_info = {}

	-- Memory usage
	local memory_kb = vim.fn.luaeval("collectgarbage('count')")
	local memory_mb = math.floor(memory_kb / 1024 * 100) / 100
	table.insert(
		perf_info,
		format_section("MEMORY USAGE", string.format("Lua memory: %.2f MB (%.0f KB)", memory_mb, memory_kb))
	)

	-- Startup time (if available)
	local startup_time = vim.fn.reltime(vim.g.start_time or vim.fn.reltime())
	local startup_ms = vim.fn.reltimefloat(startup_time) * 1000
	table.insert(perf_info, format_section("STARTUP TIME", string.format("Time since start: %.2f ms", startup_ms)))

	-- Buffer and window counts
	local buf_count = #vim.api.nvim_list_bufs()
	local win_count = #vim.api.nvim_list_wins()
	local tab_count = #vim.api.nvim_list_tabpages()
	local counts = string.format("Buffers: %d\nWindows: %d\nTabs: %d", buf_count, win_count, tab_count)
	table.insert(perf_info, format_section("RESOURCE COUNTS", counts))

	-- Recent performance issues (if any)
	local recent_errors = vim.api.nvim_exec2("messages", { output = true })
	local error_lines = {}
	for line in recent_errors.output:gmatch("[^\r\n]+") do
		if line:match("Error") or line:match("Warning") then
			table.insert(error_lines, line)
		end
	end
	if #error_lines > 0 then
		table.insert(perf_info, format_section("RECENT ERRORS/WARNINGS", table.concat(error_lines, "\n")))
	end

	-- Performance red flags and warnings
	local red_flags = {}

	-- Memory red flags
	if memory_mb > 500 then
		table.insert(red_flags, string.format("🔴 HIGH MEMORY: %.2f MB (consider restarting)", memory_mb))
	elseif memory_mb > 200 then
		table.insert(red_flags, string.format("🟡 ELEVATED MEMORY: %.2f MB", memory_mb))
	end

	-- Buffer/window red flags
	if buf_count > 50 then
		table.insert(red_flags, string.format("🔴 TOO MANY BUFFERS: %d (performance impact)", buf_count))
	elseif buf_count > 20 then
		table.insert(red_flags, string.format("🟡 MANY BUFFERS: %d", buf_count))
	end

	if win_count > 10 then
		table.insert(red_flags, string.format("🔴 TOO MANY WINDOWS: %d (layout complexity)", win_count))
	elseif win_count > 6 then
		table.insert(red_flags, string.format("🟡 MANY WINDOWS: %d", win_count))
	end

	-- Plugin loading red flags
	if package.loaded["lazy"] then
		local lazy = require("lazy")
		local plugins = lazy.plugins()
		local slow_count = 0
		local failed_count = 0
		local total_time = 0

		for _, plugin in ipairs(plugins) do
			if plugin._.error then
				failed_count = failed_count + 1
			end
			if plugin._.stats and plugin._.stats.loaded and plugin._.stats.loaded.time then
				local load_time = plugin._.stats.loaded.time
				total_time = total_time + load_time
				if load_time > 100 then
					slow_count = slow_count + 1
				end
			end
		end

		if failed_count > 0 then
			table.insert(red_flags, string.format("🔴 PLUGIN FAILURES: %d plugins failed to load", failed_count))
		end

		if slow_count > 5 then
			table.insert(red_flags, string.format("🔴 SLOW PLUGINS: %d plugins >100ms", slow_count))
		elseif slow_count > 2 then
			table.insert(red_flags, string.format("🟡 SLOW PLUGINS: %d plugins >100ms", slow_count))
		end

		if total_time > 1000 then
			table.insert(red_flags, string.format("🔴 SLOW STARTUP: %.1f ms total plugin time", total_time))
		elseif total_time > 500 then
			table.insert(red_flags, string.format("🟡 MODERATE STARTUP: %.1f ms total plugin time", total_time))
		end
	end

	-- LSP red flags
	local lsp_clients = vim.lsp.get_active_clients()
	if #lsp_clients > 5 then
		table.insert(red_flags, string.format("🔴 TOO MANY LSP CLIENTS: %d active", #lsp_clients))
	elseif #lsp_clients > 3 then
		table.insert(red_flags, string.format("🟡 MANY LSP CLIENTS: %d active", #lsp_clients))
	end

	-- Recent error red flags
	if #error_lines > 10 then
		table.insert(red_flags, string.format("🔴 MANY ERRORS: %d recent errors/warnings", #error_lines))
	elseif #error_lines > 3 then
		table.insert(red_flags, string.format("🟡 SOME ERRORS: %d recent errors/warnings", #error_lines))
	end

	-- Autocmd red flags
	local autocmd_count = 0
	for _, event in pairs(vim.api.nvim_get_autocmds({})) do
		autocmd_count = autocmd_count + 1
	end
	if autocmd_count > 200 then
		table.insert(red_flags, string.format("🔴 TOO MANY AUTOCMDS: %d registered", autocmd_count))
	elseif autocmd_count > 100 then
		table.insert(red_flags, string.format("🟡 MANY AUTOCMDS: %d registered", autocmd_count))
	end

	-- TreeSitter red flags
	if package.loaded["nvim-treesitter"] then
		local ts_parsers = require("nvim-treesitter.parsers")
		local parser_configs = ts_parsers.get_parser_configs()
		local missing_count = 0
		local broken_count = 0

		for lang, _ in pairs(parser_configs) do
			if not ts_parsers.has_parser(lang) then
				missing_count = missing_count + 1
			else
				local ok, parser = pcall(ts_parsers.get_parser, 0, lang)
				if not ok then
					broken_count = broken_count + 1
				end
			end
		end

		if broken_count > 0 then
			table.insert(red_flags, string.format("🔴 BROKEN PARSERS: %d TreeSitter parsers broken", broken_count))
		end

		if missing_count > 10 then
			table.insert(
				red_flags,
				string.format("🟡 MISSING PARSERS: %d TreeSitter parsers not installed", missing_count)
			)
		end
	end

	if #red_flags > 0 then
		table.insert(perf_info, format_section("PERFORMANCE RED FLAGS", table.concat(red_flags, "\n")))
	else
		table.insert(perf_info, format_section("PERFORMANCE RED FLAGS", "🟢 No performance issues detected"))
	end

	local log_file = write_to_log(table.concat(perf_info, ""), "capture_performance")
	return "Performance info captured to " .. log_file
end

return M
