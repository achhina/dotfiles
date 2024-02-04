return {
	-- debugger support
	{
		"mfussenegger/nvim-dap",
		config = function()
			require("config.keymaps").load_dap_keymaps()
			vim.fn.sign_define("DapBreakpoint", { text = "ß", texthl = "", linehl = "", numhl = "" })
			vim.fn.sign_define("DapBreakpointCondition", { text = "ü", texthl = "", linehl = "", numhl = "" })
		end,
	},

	-- provides nice ui
	{
		"rcarriga/nvim-dap-ui",
		dependencies = "mfussenegger/nvim-dap",
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			dapui.setup()
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

	-- python debugger
	{
		"mfussenegger/nvim-dap-python",
		ft = "python",
		dependencies = {
			"mfussenegger/nvim-dap",
			"rcarriga/nvim-dap-ui",
		},
		config = function()
			require("dap-python").setup("~/venv/debugpy/bin/python")

			-- Add configuration overrides
			local configurations = require("dap").configurations.python
			for _, configuration in pairs(configurations) do
				configuration.justMyCode = false
			end
		end,
	},

	-- virtual text support
	{
		"theHamsta/nvim-dap-virtual-text",
		ft = "python",
		dependencies = {
			"mfussenegger/nvim-dap",
			"rcarriga/nvim-dap-ui",
		},
		config = function()
			require("nvim-dap-virtual-text").setup({
				enabled = true,

				-- DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, DapVirtualTextForceRefresh
				enabled_commands = false,

				-- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
				highlight_changed_variables = true,
				highlight_new_as_changed = true,

				-- prefix virtual text with comment string
				commented = false,

				show_stop_reason = true,

				-- experimental features:
				-- virt_text_pos = "eol", -- position of virtual text, see `:h nvim_buf_set_extmark()`
				-- all_frames = true, -- show virtual text for all stack frames not only current
			})
		end,
	},
}
