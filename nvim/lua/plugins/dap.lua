return {
	-- Auto-install debug adapters
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"mfussenegger/nvim-dap",
		},
		config = function()
			require("mason-nvim-dap").setup({
				ensure_installed = {
					"python", -- Python debugger
					"node2", -- Node.js/JavaScript debugger
					"chrome", -- Chrome DevTools for web debugging
					"codelldb", -- Rust/C/C++ debugger
				},
				automatic_installation = true,
				handlers = {
					-- Default handler for auto-setup
					function(config)
						require("mason-nvim-dap").default_setup(config)
					end,
					-- Custom configurations
					python = function(config)
						config.adapters = {
							type = "executable",
							command = "python",
							args = {
								"-m",
								"debugpy.adapter",
							},
						}
						require("mason-nvim-dap").default_setup(config)
					end,
				},
			})
		end,
	},

	-- Core debugging support
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"nvim-neotest/nvim-nio",
		},
		keys = {
			{ "<leader>d", "", desc = "+debug", mode = { "n", "v" } },
		},
		config = function()
			local dap = require("dap")

			-- Enhanced sign definitions
			vim.fn.sign_define("DapBreakpoint", {
				text = "🔴",
				texthl = "DiagnosticError",
				linehl = "DapBreakpointLine",
				numhl = "DiagnosticError",
			})
			vim.fn.sign_define("DapBreakpointCondition", {
				text = "🟡",
				texthl = "DiagnosticWarn",
				linehl = "DapBreakpointLine",
				numhl = "DiagnosticWarn",
			})
			vim.fn.sign_define("DapLogPoint", {
				text = "📝",
				texthl = "DiagnosticInfo",
				linehl = "DapBreakpointLine",
				numhl = "DiagnosticInfo",
			})
			vim.fn.sign_define("DapStopped", {
				text = "▶️",
				texthl = "DiagnosticWarn",
				linehl = "DapStoppedLine",
				numhl = "DiagnosticWarn",
			})
			vim.fn.sign_define("DapBreakpointRejected", {
				text = "❌",
				texthl = "DiagnosticError",
				linehl = "DapBreakpointLine",
				numhl = "DiagnosticError",
			})

			-- Enhanced session management
			dap.listeners.after.event_initialized["dap_config"] = function(session)
				require("config.keymaps").load_dap_keymaps()
				vim.notify("Debug session started: " .. session.config.name, vim.log.levels.INFO)
			end

			dap.listeners.before.event_terminated["dap_config"] = function(session)
				-- Clear DAP keymaps
				local keymaps_to_clear = {
					"<leader>ds",
					"<leader>dS",
					"<leader>dn",
					"<leader>di",
					"<leader>do",
					"<leader>dc",
					"<leader>dr",
					"<leader>db",
					"<leader>dB",
					"<leader>dl",
					"<leader>de",
					"<leader>dE",
					"<leader>du",
					"<leader>dR",
					"<leader>dt",
					"<leader>dq",
					"<leader>dh",
				}
				for _, keymap in ipairs(keymaps_to_clear) do
					pcall(vim.keymap.del, "n", keymap)
				end
				if session then
					vim.notify(
						"Debug session terminated: " .. (session.config and session.config.name or "unknown"),
						vim.log.levels.INFO
					)
				end
			end

			dap.listeners.before.event_exited["dap_config"] = function(session)
				-- Same cleanup as terminated
				local keymaps_to_clear = {
					"<leader>ds",
					"<leader>dS",
					"<leader>dn",
					"<leader>di",
					"<leader>do",
					"<leader>dc",
					"<leader>dr",
					"<leader>db",
					"<leader>dB",
					"<leader>dl",
					"<leader>de",
					"<leader>dE",
					"<leader>du",
					"<leader>dR",
					"<leader>dt",
					"<leader>dq",
					"<leader>dh",
				}
				for _, keymap in ipairs(keymaps_to_clear) do
					pcall(vim.keymap.del, "n", keymap)
				end
				if session then
					vim.notify(
						"Debug session exited: " .. (session.config and session.config.name or "unknown"),
						vim.log.levels.INFO
					)
				end
			end

			-- Load advanced debugging profiles and configurations
			require("config.debug-profiles").setup()

			-- Load inline debugging enhancements
			require("config.inline-debug").setup()
		end,
	},

	-- Enhanced debugging UI
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},
		keys = {
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "Debug: Toggle UI",
			},
			{
				"<leader>de",
				function()
					require("dapui").eval()
				end,
				desc = "Debug: Evaluate Expression",
				mode = { "n", "v" },
			},
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup({
				controls = {
					element = "repl",
					enabled = true,
					icons = {
						disconnect = "⏹",
						pause = "⏸",
						play = "▶",
						run_last = "⏮",
						step_back = "⏪",
						step_into = "⏬",
						step_out = "⏫",
						step_over = "⏭",
						terminate = "⏹",
					},
				},
				element_mappings = {
					scopes = {
						edit = "e",
						expand = { "<CR>", "<2-LeftMouse>" },
						repl = "r",
						toggle = "t",
					},
					watches = {
						edit = "e",
						expand = { "<CR>", "<2-LeftMouse>" },
						remove = "d",
						repl = "r",
						toggle = "t",
					},
				},
				expand_lines = true,
				floating = {
					border = "rounded",
					mappings = {
						close = { "q", "<Esc>" },
					},
				},
				force_buffers = true,
				icons = {
					collapsed = "▶",
					current_frame = "▶",
					expanded = "▼",
				},
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.25 },
							{ id = "breakpoints", size = 0.25 },
							{ id = "stacks", size = 0.25 },
							{ id = "watches", size = 0.25 },
						},
						position = "left",
						size = 40,
					},
					{
						elements = {
							{ id = "repl", size = 0.5 },
							{ id = "console", size = 0.5 },
						},
						position = "bottom",
						size = 10,
					},
				},
				mappings = {
					edit = "e",
					expand = { "<CR>", "<2-LeftMouse>" },
					open = "o",
					remove = "d",
					repl = "r",
					toggle = "t",
				},
				render = {
					indent = 1,
					max_value_lines = 100,
				},
			})

			-- Auto-open/close UI
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
		end,
	},

	-- Simple DAP navigation using built-in vim functionality
	{
		"mfussenegger/nvim-dap",
		keys = {
			{
				"<leader>dfc",
				function()
					-- Show DAP configurations using vim.ui.select
					local dap = require("dap")
					local configs = {}
					for ft, config_list in pairs(dap.configurations) do
						for _, config in ipairs(config_list) do
							table.insert(configs, ft .. ": " .. config.name)
						end
					end
					vim.ui.select(configs, {
						prompt = "Debug Configurations:",
					}, function(choice)
						if choice then
							vim.notify("Selected: " .. choice, vim.log.levels.INFO)
						end
					end)
				end,
				desc = "Debug: Configurations",
			},
			{
				"<leader>dfb",
				function()
					-- List breakpoints using quickfix
					local dap = require("dap")
					local breakpoints = dap.list_breakpoints()
					local qf_list = {}
					for _, bp in pairs(breakpoints) do
						for _, item in ipairs(bp) do
							table.insert(qf_list, {
								filename = item.file,
								lnum = item.line,
								text = "Breakpoint",
							})
						end
					end
					vim.fn.setqflist(qf_list)
					vim.cmd("copen")
				end,
				desc = "Debug: List Breakpoints",
			},
		},
	},

	-- Enhanced Python debugging
	{
		"mfussenegger/nvim-dap-python",
		ft = "python",
		dependencies = {
			"mfussenegger/nvim-dap",
			"rcarriga/nvim-dap-ui",
		},
		build = false, -- Disable luarocks build, we use system debugpy
		keys = {
			{
				"<leader>dpt",
				function()
					require("dap-python").test_method()
				end,
				desc = "Debug: Test Method",
				ft = "python",
			},
			{
				"<leader>dpc",
				function()
					require("dap-python").test_class()
				end,
				desc = "Debug: Test Class",
				ft = "python",
			},
			{
				"<leader>dps",
				function()
					require("dap-python").debug_selection()
				end,
				desc = "Debug: Debug Selection",
				mode = "v",
				ft = "python",
			},
		},
		config = function()
			-- Try to find Python with debugpy installed
			local python_path = vim.fn.exepath("python3") or vim.fn.exepath("python")

			-- Setup with fallback paths
			local debugpy_python = python_path
			if vim.fn.isdirectory(vim.fn.expand("~/venv/debugpy")) == 1 then
				debugpy_python = "~/venv/debugpy/bin/python"
			elseif vim.fn.isdirectory(vim.fn.expand("~/.virtualenvs/debugpy")) == 1 then
				debugpy_python = "~/.virtualenvs/debugpy/bin/python"
			end

			require("dap-python").setup(debugpy_python)

			-- Enhanced Python configurations
			local dap = require("dap")
			table.insert(dap.configurations.python, {
				name = "Python: Django",
				type = "python",
				request = "launch",
				program = vim.fn.getcwd() .. "/manage.py",
				args = { "runserver", "--noreload" },
				django = true,
				justMyCode = false,
			})

			table.insert(dap.configurations.python, {
				name = "Python: Flask",
				type = "python",
				request = "launch",
				module = "flask",
				env = { FLASK_APP = "app.py" },
				args = { "run", "--debug" },
				justMyCode = false,
			})

			table.insert(dap.configurations.python, {
				name = "Python: FastAPI",
				type = "python",
				request = "launch",
				module = "uvicorn",
				args = { "main:app", "--reload" },
				justMyCode = false,
			})

			-- Override default configurations
			for _, configuration in pairs(dap.configurations.python) do
				configuration.justMyCode = false
				configuration.console = "integratedTerminal"
			end
		end,
	},

	-- Enhanced virtual text support (works with all languages)
	{
		"theHamsta/nvim-dap-virtual-text",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-treesitter/nvim-treesitter",
		},
		keys = {
			{
				"<leader>dvt",
				function()
					require("nvim-dap-virtual-text").toggle()
				end,
				desc = "Debug: Toggle Virtual Text",
			},
		},
		config = function()
			require("nvim-dap-virtual-text").setup({
				enabled = true,
				enabled_commands = true,
				highlight_changed_variables = true,
				highlight_new_as_changed = true,
				show_stop_reason = true,
				commented = false,
				only_first_definition = true,
				all_references = false,
				clear_on_continue = false,
				display_callback = function(variable, _, _, _, options)
					-- Custom display formatting
					if options.virt_text_pos == "inline" then
						return " = " .. variable.value
					else
						return variable.name .. " = " .. variable.value
					end
				end,
				virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",
				all_frames = false,
				virt_lines = false,
				virt_text_win_col = nil,
			})
		end,
	},

	-- Note: Removed persistent-breakpoints and goto-breakpoints plugins
	-- These were redundant with DAP's built-in breakpoint management

	-- Debug profiles and configurations
	{
		"LiadOz/nvim-dap-repl-highlights",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("nvim-dap-repl-highlights").setup()
		end,
	},
}
