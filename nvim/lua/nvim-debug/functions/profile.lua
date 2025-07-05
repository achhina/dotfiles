local M = {}

local function get_timestamp()
	return os.date("%Y-%m-%d_%H-%M-%S")
end

local function get_profile_dir()
	local data_dir = vim.fn.stdpath("data")
	local profile_dir = data_dir .. "/debug/profiles"
	vim.fn.mkdir(profile_dir, "p")
	return profile_dir
end

local profile_state = {
	active = false,
	start_time = nil,
	profile_file = nil,
}

function M.toggle_profile()
	if profile_state.active then
		-- Stop profiling
		local duration = vim.fn.reltimefloat(vim.fn.reltime(profile_state.start_time))

		-- Stop profiling
		vim.cmd("profile stop")

		-- Reset state
		local profile_file = profile_state.profile_file
		profile_state.active = false
		profile_state.start_time = nil
		profile_state.profile_file = nil

		return string.format("Profiling stopped after %.2f seconds. Profile saved to %s", duration, profile_file)
	else
		-- Start profiling
		local profile_dir = get_profile_dir()
		local timestamp = get_timestamp()
		local profile_file = profile_dir .. "/profile_" .. timestamp .. ".txt"

		-- Start profiling with comprehensive options
		vim.cmd("profile start " .. profile_file)
		vim.cmd("profile func *")
		vim.cmd("profile file *")

		profile_state.active = true
		profile_state.start_time = vim.fn.reltime()
		profile_state.profile_file = profile_file

		return "Profiling started. Profile will be saved to " .. profile_file
	end
end

-- Keep individual functions for backward compatibility
function M.start_profile()
	if profile_state.active then
		return "Profiling already active. Use toggle_profile or stop_profile to stop first."
	end
	return M.toggle_profile()
end

function M.stop_profile()
	if not profile_state.active then
		return "No active profiling session. Use toggle_profile or start_profile to start first."
	end
	return M.toggle_profile()
end

function M.profile_startup()
	local profile_dir = get_profile_dir()
	local timestamp = get_timestamp()
	local profile_file = profile_dir .. "/startup_" .. timestamp .. ".txt"

	-- Create a startup profiling script
	local startup_script = profile_dir .. "/startup_script.vim"
	local script_content = string.format(
		[[
profile start %s
profile func *
profile file *
]],
		profile_file
	)

	local file = io.open(startup_script, "w")
	if file then
		file:write(script_content)
		file:close()
	else
		return "Failed to create startup profiling script"
	end

	-- Inform user about manual restart
	local instructions = string.format(
		[[
Startup profiling prepared. To profile startup:
1. Restart Neovim with: nvim --cmd "source %s"
2. After startup completes, run: :profile stop
3. Results will be in: %s

Or use the restart command if available:
:RestartWithProfile
]],
		startup_script,
		profile_file
	)

	-- Create a helper command for restart
	vim.api.nvim_create_user_command("RestartWithProfile", function()
		vim.cmd("qall!")
		-- Note: This won't actually restart, but will quit cleanly
	end, { desc = "Quit to restart with profiling" })

	return instructions
end

-- Helper function to analyze existing profile files
function M.list_profiles()
	local profile_dir = get_profile_dir()
	local profiles = vim.fn.glob(profile_dir .. "/*.txt", false, true)

	if #profiles == 0 then
		return "No profile files found in " .. profile_dir
	end

	local profile_list = {}
	for _, profile in ipairs(profiles) do
		local filename = vim.fn.fnamemodify(profile, ":t")
		local size = vim.fn.getfsize(profile)
		local modified = vim.fn.getftime(profile)
		local date = os.date("%Y-%m-%d %H:%M:%S", modified)

		table.insert(profile_list, string.format("%s (%d bytes, %s)", filename, size, date))
	end

	return "Profile files in " .. profile_dir .. ":\n" .. table.concat(profile_list, "\n")
end

-- Helper function to get profiling status
function M.profile_status()
	if profile_state.active then
		local duration = vim.fn.reltimefloat(vim.fn.reltime(profile_state.start_time))
		return string.format("Profiling active for %.2f seconds. Output: %s", duration, profile_state.profile_file)
	else
		return "No active profiling session."
	end
end

return M
