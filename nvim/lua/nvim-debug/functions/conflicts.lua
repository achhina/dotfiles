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

function M.check_keymaps()
	local keymaps = {}
	local conflicts = {}

	-- Get all keymaps for different modes
	local modes = { "n", "i", "v", "x", "s", "o", "c", "t" }
	local mode_names = {
		n = "Normal",
		i = "Insert",
		v = "Visual",
		x = "Visual Block",
		s = "Select",
		o = "Operator-pending",
		c = "Command-line",
		t = "Terminal",
	}

	for _, mode in ipairs(modes) do
		local mode_keymaps = vim.api.nvim_get_keymap(mode)
		for _, keymap in ipairs(mode_keymaps) do
			local key = mode .. ":" .. keymap.lhs

			if keymaps[key] then
				-- Found a conflict
				table.insert(conflicts, {
					mode = mode,
					key = keymap.lhs,
					original = keymaps[key],
					conflict = keymap,
				})
			else
				keymaps[key] = keymap
			end
		end
	end

	-- Format output
	local output = {}

	-- List all keymaps by mode
	for _, mode in ipairs(modes) do
		local mode_maps = {}
		for key, keymap in pairs(keymaps) do
			if key:match("^" .. mode .. ":") then
				local desc = keymap.desc or "No description"
				local rhs = keymap.rhs or keymap.callback and "[function]" or "[unknown]"
				table.insert(mode_maps, string.format("  %s -> %s (%s)", keymap.lhs, rhs, desc))
			end
		end

		if #mode_maps > 0 then
			table.insert(output, mode_names[mode] .. " mode keymaps (" .. #mode_maps .. "):")
			table.insert(output, table.concat(mode_maps, "\n"))
			table.insert(output, "")
		end
	end

	-- List conflicts
	if #conflicts > 0 then
		table.insert(output, "KEYMAP CONFLICTS DETECTED:")
		for _, conflict in ipairs(conflicts) do
			table.insert(output, string.format("Mode %s, Key '%s':", mode_names[conflict.mode], conflict.key))
			table.insert(output, string.format("  Original: %s", conflict.original.rhs or "[function]"))
			table.insert(output, string.format("  Conflict: %s", conflict.conflict.rhs or "[function]"))
			table.insert(output, "")
		end
	else
		table.insert(output, "No keymap conflicts detected.")
	end

	local log_file = write_to_log(format_section("KEYMAP ANALYSIS", table.concat(output, "\n")), "check_keymaps")
	return string.format("Keymap analysis complete. %d conflicts found. Details in %s", #conflicts, log_file)
end

function M.check_autocmds()
	local autocmds = {}
	local groups = {}

	-- Get all autocmds
	local all_autocmds = vim.api.nvim_get_autocmds({})

	for _, autocmd in ipairs(all_autocmds) do
		local event = autocmd.event
		if event then
			local group_name = autocmd.group_name or "default"

			-- Track by group
			if not groups[group_name] then
				groups[group_name] = {}
			end
			table.insert(groups[group_name], autocmd)

			-- Track by event
			if not autocmds[event] then
				autocmds[event] = {}
			end
			table.insert(autocmds[event], autocmd)
		end
	end

	-- Format output
	local output = {}

	-- List autocmds by event
	table.insert(output, "AUTOCMDS BY EVENT:")
	for event, event_autocmds in pairs(autocmds) do
		table.insert(output, string.format("%s (%d autocmds):", event, #event_autocmds))
		for _, autocmd in ipairs(event_autocmds) do
			local pattern = autocmd.pattern or "*"
			local group = autocmd.group_name or "default"
			local desc = autocmd.desc or "No description"
			table.insert(output, string.format("  Pattern: %s, Group: %s - %s", pattern, group, desc))
		end
		table.insert(output, "")
	end

	-- List autocmds by group
	table.insert(output, "AUTOCMDS BY GROUP:")
	for group_name, group_autocmds in pairs(groups) do
		table.insert(output, string.format("%s (%d autocmds):", group_name, #group_autocmds))
		for _, autocmd in ipairs(group_autocmds) do
			local event = autocmd.event
			local pattern = autocmd.pattern or "*"
			local desc = autocmd.desc or "No description"
			table.insert(output, string.format("  %s:%s - %s", event, pattern, desc))
		end
		table.insert(output, "")
	end

	-- Check for potential issues
	local issues = {}

	-- Check for duplicate autocmds
	for event, event_autocmds in pairs(autocmds) do
		local patterns = {}
		for _, autocmd in ipairs(event_autocmds) do
			local pattern = autocmd.pattern or "*"
			local key = event .. ":" .. pattern
			if patterns[key] then
				table.insert(issues, string.format("Duplicate autocmd: %s", key))
			else
				patterns[key] = true
			end
		end
	end

	if #issues > 0 then
		table.insert(output, "POTENTIAL ISSUES:")
		table.insert(output, table.concat(issues, "\n"))
	else
		table.insert(output, "No autocmd issues detected.")
	end

	local log_file = write_to_log(format_section("AUTOCMD ANALYSIS", table.concat(output, "\n")), "check_autocmds")
	return string.format(
		"Autocmd analysis complete. %d events, %d groups analyzed. Details in %s",
		vim.tbl_count(autocmds),
		vim.tbl_count(groups),
		log_file
	)
end

return M
