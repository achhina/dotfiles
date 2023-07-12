return {
  -- debugger support
  'mfussenegger/nvim-dap',
  
  -- provides nice ui
  {
    'rcarriga/nvim-dap-ui',
    dependencies = 'mfussenegger/nvim-dap',
    config = function ()
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
    ft = 'python',
    dependencies = {
      'mfussenegger/nvim-dap',
      'rcarriga/nvim-dap-ui',
    }
  },
}
