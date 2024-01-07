vim.fn.sign_define("DapBreakpoint", { text = "ß", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "ü", texthl = "", linehl = "", numhl = "" })

return {
    -- debugger support
    {
        'mfussenegger/nvim-dap',
        config = function()
            local dap = require('dap')
            local dapui = require('dapui')

            local nmap = function(keys, func, desc)
                if desc then
                    desc = '[D]AP: ' .. desc
                end
                vim.keymap.set('n', keys, func, { silent = true, desc = desc })
            end

            nmap("<leader>ds", dap.step_into, "[S]tep into")
            nmap("<leader>dS", dap.step_back, "[S]tep back")
            nmap("<leader>dn", dap.step_over, "[N]ext | [S]tep Over")
            nmap("<leader>dds", dap.step_out, "[D] [S]tep Out")
            nmap("<leader>dc", dap.continue, "[C]ontinue")
            nmap("<leader>dr", dap.repl.open, "[R]EPL Open")
            nmap("<leader>db", dap.toggle_breakpoint, "Toggle [B]reakpoint")
            nmap(
                "<leader>dB",
                function()
                    dap.set_breakpoint(vim.fn.input "[DAP] Condition > ")
                end,
                "Set [B]reakpoint"
            )
            nmap("<leader>de", dapui.eval, "[E]valuate")
            nmap(
                "<leader>dE",
                function()
                    dapui.eval(vim.fn.input "[DAP] Expression > ")
                end,
                "[E]xpression"
            )
        end
    },

    -- provides nice ui
    {
        'rcarriga/nvim-dap-ui',
        dependencies = 'mfussenegger/nvim-dap',
        config = function()
            local dap = require('dap')
            local dapui = require('dapui')
            dapui.setup()
            dap.listeners.after.event_initialized['dapui_config'] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated['dapui_config'] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited['dapui_config'] = function()
                dapui.close()
            end
        end
    },

    -- python debugger
    {
        'mfussenegger/nvim-dap-python',
        ft           = 'python',
        dependencies = {
            'mfussenegger/nvim-dap',
            'rcarriga/nvim-dap-ui',
        },
        config       = function()
            require('dap-python').setup('~/venv/debugpy/bin/python')

            -- Add configuration overrides
            local configurations = require('dap').configurations.python
            for _, configuration in pairs(configurations) do
                configuration.justMyCode = false
            end
        end
    },

    -- virtual text support
    {
        'theHamsta/nvim-dap-virtual-text',
        ft = 'python',
        dependencies = {
            'mfussenegger/nvim-dap',
            'rcarriga/nvim-dap-ui',
        },
        config = function()
            require("nvim-dap-virtual-text").setup {
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
            }
        end
    },
}
