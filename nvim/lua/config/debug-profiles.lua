-- Advanced debugging profiles and configurations
-- This module provides debug profiles, auto-attach, and enhanced debugging workflows

local M = {}

-- Debug profiles for different scenarios
M.profiles = {
	-- Web development profiles
	web = {
		{
			name = "Frontend: React Dev Server",
			type = "chrome",
			request = "launch",
			url = "http://localhost:3000",
			webRoot = "${workspaceFolder}/src",
			userDataDir = false,
			runtimeExecutable = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
		},
		{
			name = "Frontend: Next.js Dev",
			type = "chrome",
			request = "launch",
			url = "http://localhost:3000",
			webRoot = "${workspaceFolder}",
			userDataDir = false,
		},
		{
			name = "Backend: Node.js API",
			type = "node2",
			request = "launch",
			program = "${workspaceFolder}/server.js",
			env = { NODE_ENV = "development" },
			console = "integratedTerminal",
			skipFiles = { "<node_internals>/**" },
		},
		{
			name = "Backend: Express with TypeScript",
			type = "node2",
			request = "launch",
			program = "${workspaceFolder}/dist/server.js",
			preLaunchTask = "typescript: build",
			env = { NODE_ENV = "development" },
			console = "integratedTerminal",
			skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
		},
	},

	-- Python development profiles
	python = {
		{
			name = "Python: FastAPI Development",
			type = "python",
			request = "launch",
			module = "uvicorn",
			args = { "main:app", "--reload", "--host", "0.0.0.0", "--port", "8000" },
			console = "integratedTerminal",
			justMyCode = false,
			env = { PYTHONPATH = "${workspaceFolder}" },
		},
		{
			name = "Python: Django Development",
			type = "python",
			request = "launch",
			program = "${workspaceFolder}/manage.py",
			args = { "runserver", "0.0.0.0:8000", "--noreload" },
			console = "integratedTerminal",
			justMyCode = false,
			django = true,
		},
		{
			name = "Python: Pytest Current File",
			type = "python",
			request = "launch",
			module = "pytest",
			args = { "${file}", "-v" },
			console = "integratedTerminal",
			justMyCode = false,
		},
		{
			name = "Python: Pytest with Coverage",
			type = "python",
			request = "launch",
			module = "pytest",
			args = { "--cov=.", "--cov-report=html", "-v" },
			console = "integratedTerminal",
			justMyCode = false,
		},
	},

	-- Rust development profiles
	rust = {
		{
			name = "Rust: Debug Binary",
			type = "codelldb",
			request = "launch",
			program = function()
				-- Auto-detect target binary
				local handle = io.popen("find target/debug -maxdepth 1 -type f -executable | head -1")
				if not handle then
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
				end
				local result = handle:read("*a"):gsub("%s+", "")
				handle:close()
				return result ~= "" and result
					or vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
			end,
			cwd = "${workspaceFolder}",
			stopOnEntry = false,
		},
		{
			name = "Rust: Test Current Package",
			type = "codelldb",
			request = "launch",
			program = function()
				-- Get current package name and build test binary
				local handle = io.popen(
					"cargo metadata --format-version 1 | jq -r '.packages[] | select(.manifest_path | contains(\""
						.. vim.fn.getcwd()
						.. "\")) | .name'"
				)
				if not handle then
					return vim.fn.input("Path to test executable: ", vim.fn.getcwd() .. "/target/debug/deps/", "file")
				end
				local package_name = handle:read("*a"):gsub("%s+", "")
				handle:close()
				return vim.fn.getcwd() .. "/target/debug/deps/" .. package_name:gsub("-", "_")
			end,
			args = { "--test" },
			cwd = "${workspaceFolder}",
			stopOnEntry = false,
		},
	},

	-- Container debugging profiles
	container = {
		{
			name = "Docker: Attach to Python Container",
			type = "python",
			request = "attach",
			host = "localhost",
			port = 5678,
			pathMappings = {
				{
					localRoot = "${workspaceFolder}",
					remoteRoot = "/app",
				},
			},
		},
		{
			name = "Docker: Attach to Node Container",
			type = "node2",
			request = "attach",
			host = "localhost",
			port = 9229,
			localRoot = "${workspaceFolder}",
			remoteRoot = "/usr/src/app",
			skipFiles = { "<node_internals>/**" },
		},
	},
}

-- Auto-attach functionality
M.auto_attach = {
	-- Find and attach to running processes
	attach_to_process = function(pattern)
		local handle = io.popen("ps aux | grep '" .. pattern .. "' | grep -v grep | awk '{print $2, $11}'")
		if not handle then
			vim.notify("Failed to execute ps command", vim.log.levels.ERROR)
			return
		end
		local processes = {}

		for line in handle:lines() do
			local pid, cmd = line:match("(%d+)%s+(.+)")
			if pid then
				table.insert(processes, { pid = pid, cmd = cmd })
			end
		end
		handle:close()

		if #processes == 0 then
			vim.notify("No processes found matching: " .. pattern, vim.log.levels.WARN)
			return
		end

		-- If multiple processes, let user choose
		if #processes > 1 then
			local choices = {}
			for i, proc in ipairs(processes) do
				table.insert(choices, i .. ": [" .. proc.pid .. "] " .. proc.cmd)
			end

			local choice = vim.fn.inputlist(vim.list_extend({ "Select process:" }, choices))
			if choice > 0 and choice <= #processes then
				M.auto_attach.attach_to_pid(processes[choice].pid)
			end
		else
			M.auto_attach.attach_to_pid(processes[1].pid)
		end
	end,

	attach_to_pid = function(pid)
		local dap = require("dap")

		-- Try to determine process type and attach appropriately
		local handle = io.popen("ps -p " .. pid .. " -o comm=")
		if not handle then
			vim.notify("Failed to determine process type for PID " .. pid, vim.log.levels.ERROR)
			return
		end
		local comm = handle:read("*a"):gsub("%s+", "")
		handle:close()

		local config = {
			name = "Attach to PID " .. pid,
			request = "attach",
			processId = pid,
		}

		-- Set appropriate adapter based on process
		if comm:match("python") then
			config.type = "python"
			config.host = "localhost"
			config.port = 5678
		elseif comm:match("node") then
			config.type = "node2"
			config.host = "localhost"
			config.port = 9229
		else
			config.type = "codelldb"
		end

		dap.run(config)
	end,

	-- Auto-attach to development servers
	auto_attach_dev_servers = function()
		-- Common development server patterns
		local patterns = {
			"python.*uvicorn",
			"python.*manage.py.*runserver",
			"node.*dev",
			"npm.*start",
			"yarn.*dev",
		}

		for _, pattern in ipairs(patterns) do
			M.auto_attach.attach_to_process(pattern)
		end
	end,
}

-- Enhanced debugging workflows
M.workflows = {
	-- Quick test debugging
	debug_current_test = function()
		local ft = vim.bo.filetype
		local dap = require("dap")

		if ft == "python" then
			-- Find current test function/class
			local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

			-- Search backwards for test function or class
			local test_name = nil
			for i = cursor_line, 1, -1 do
				local l = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
				local match = l:match("def (test_%w+)")
				if match then
					test_name = match
					break
				end
			end

			if test_name then
				dap.run({
					name = "Debug Test: " .. test_name,
					type = "python",
					request = "launch",
					module = "pytest",
					args = { "${file}::" .. test_name, "-v", "-s" },
					console = "integratedTerminal",
					justMyCode = false,
				})
			else
				vim.notify("No test function found", vim.log.levels.WARN)
			end
		elseif ft == "javascript" or ft == "typescript" then
			-- Debug JavaScript/TypeScript test
			local test_framework = M.workflows.detect_js_test_framework()
			if test_framework then
				dap.run({
					name = "Debug JS Test: " .. vim.fn.expand("%:t"),
					type = "node2",
					request = "launch",
					program = "${workspaceFolder}/node_modules/" .. test_framework .. "/bin/" .. test_framework,
					args = { "${file}" },
					console = "integratedTerminal",
					skipFiles = { "<node_internals>/**" },
				})
			end
		end
	end,

	detect_js_test_framework = function()
		-- Check package.json for test frameworks
		local package_json = vim.fn.getcwd() .. "/package.json"
		if vim.fn.filereadable(package_json) == 1 then
			local content = table.concat(vim.fn.readfile(package_json), "\n")
			if content:match("jest") then
				return "jest"
			end
			if content:match("mocha") then
				return "mocha"
			end
			if content:match("vitest") then
				return "vitest"
			end
		end
		return nil
	end,

	-- Remote debugging setup
	setup_remote_debugging = function()
		local remote_host = vim.fn.input("Remote host: ", "localhost")
		local remote_port = vim.fn.input("Remote port: ", "5678")
		local local_root = vim.fn.input("Local root: ", vim.fn.getcwd())
		local remote_root = vim.fn.input("Remote root: ", "/app")

		local dap = require("dap")
		dap.run({
			name = "Remote Debug: " .. remote_host .. ":" .. remote_port,
			type = "python", -- Default to Python, could be made configurable
			request = "attach",
			host = remote_host,
			port = tonumber(remote_port),
			pathMappings = {
				{
					localRoot = local_root,
					remoteRoot = remote_root,
				},
			},
		})
	end,

	-- Performance profiling integration
	profile_and_debug = function()
		local ft = vim.bo.filetype

		if ft == "python" then
			-- Use cProfile with debugging
			local dap = require("dap")
			dap.run({
				name = "Profile & Debug Python",
				type = "python",
				request = "launch",
				module = "cProfile",
				args = { "-o", "/tmp/profile.out", "${file}" },
				console = "integratedTerminal",
				justMyCode = false,
				postDebugTask = function()
					-- Open profile results
					vim.cmd("tabnew")
					vim.cmd(
						"terminal python -c \"import pstats; pstats.Stats('/tmp/profile.out').sort_stats('cumulative').print_stats(20)\""
					)
				end,
			})
		elseif ft == "javascript" or ft == "typescript" then
			-- Use Node.js profiler
			local dap = require("dap")
			dap.run({
				name = "Profile & Debug Node.js",
				type = "node2",
				request = "launch",
				program = "${file}",
				args = { "--prof" },
				console = "integratedTerminal",
				skipFiles = { "<node_internals>/**" },
			})
		end
	end,
}

-- Session management
M.sessions = {
	save_session = function(name)
		local dap = require("dap")
		local session_data = {
			breakpoints = dap.list_breakpoints(),
			configurations = dap.configurations,
			session_info = dap.session and dap.session.config and {
				name = dap.session.config.name,
				type = dap.session.config.type,
			} or nil,
		}

		local session_file = vim.fn.stdpath("data") .. "/dap_sessions/" .. (name or "default") .. ".json"
		vim.fn.mkdir(vim.fn.fnamemodify(session_file, ":h"), "p")

		local file = io.open(session_file, "w")
		if file then
			file:write(vim.fn.json_encode(session_data))
			file:close()
			vim.notify("Debug session saved: " .. name, vim.log.levels.INFO)
		end
	end,

	load_session = function(name)
		local session_file = vim.fn.stdpath("data") .. "/dap_sessions/" .. (name or "default") .. ".json"

		if vim.fn.filereadable(session_file) == 1 then
			local content = table.concat(vim.fn.readfile(session_file), "\n")
			local session_data = vim.fn.json_decode(content)

			-- Restore breakpoints
			if session_data.breakpoints then
				local dap = require("dap")
				for _, breakpoints in pairs(session_data.breakpoints) do
					for _, bp in ipairs(breakpoints) do
						dap.set_breakpoint(bp.condition, bp.hit_condition, bp.log_message)
					end
				end
			end

			vim.notify("Debug session loaded: " .. name, vim.log.levels.INFO)
		else
			vim.notify("Session not found: " .. name, vim.log.levels.WARN)
		end
	end,
}

-- Setup function to register all enhancements
function M.setup()
	local dap = require("dap")

	-- Register all profiles
	for lang, configs in pairs(M.profiles) do
		for _, config in ipairs(configs) do
			if not dap.configurations[lang] then
				dap.configurations[lang] = {}
			end
			table.insert(dap.configurations[lang], config)
		end
	end

	-- Create user commands
	vim.api.nvim_create_user_command("DapAttachProcess", function(opts)
		M.auto_attach.attach_to_process(opts.args)
	end, { nargs = 1, desc = "Attach to process by pattern" })

	vim.api.nvim_create_user_command("DapAttachPid", function(opts)
		M.auto_attach.attach_to_pid(opts.args)
	end, { nargs = 1, desc = "Attach to process by PID" })

	vim.api.nvim_create_user_command("DapDebugTest", function()
		M.workflows.debug_current_test()
	end, { desc = "Debug current test function" })

	vim.api.nvim_create_user_command("DapRemoteDebug", function()
		M.workflows.setup_remote_debugging()
	end, { desc = "Setup remote debugging" })

	vim.api.nvim_create_user_command("DapProfile", function()
		M.workflows.profile_and_debug()
	end, { desc = "Profile and debug current file" })

	vim.api.nvim_create_user_command("DapSaveSession", function(opts)
		M.sessions.save_session(opts.args)
	end, { nargs = "?", desc = "Save debug session" })

	vim.api.nvim_create_user_command("DapLoadSession", function(opts)
		M.sessions.load_session(opts.args)
	end, { nargs = "?", desc = "Load debug session" })

	-- Advanced debug features grouped logically
	-- da* = attach operations
	vim.keymap.set("n", "<leader>da", "", { desc = "+attach" })
	vim.keymap.set("n", "<leader>dap", function()
		M.auto_attach.attach_to_process(vim.fn.input("Process pattern: "))
	end, { desc = "Debug: Attach to Process" })
	vim.keymap.set(
		"n",
		"<leader>daa",
		M.auto_attach.auto_attach_dev_servers,
		{ desc = "Debug: Auto-attach Dev Servers" }
	)

	-- dr* = remote/advanced debugging
	vim.keymap.set("n", "<leader>dr", "", { desc = "+remote" })
	vim.keymap.set("n", "<leader>drd", M.workflows.setup_remote_debugging, { desc = "Debug: Remote Debug" })
	vim.keymap.set("n", "<leader>drf", M.workflows.profile_and_debug, { desc = "Debug: Profile & Debug" })

	-- ds* = session management
	vim.keymap.set("n", "<leader>ds", "", { desc = "+session" })
	vim.keymap.set("n", "<leader>dss", function()
		M.sessions.save_session(vim.fn.input("Session name: "))
	end, { desc = "Debug: Save Session" })
	vim.keymap.set("n", "<leader>dsl", function()
		M.sessions.load_session(vim.fn.input("Session name: "))
	end, { desc = "Debug: Load Session" })
end

return M
