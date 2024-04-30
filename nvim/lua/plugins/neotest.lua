return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"nvim-neotest/neotest-python",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		local neotest = require("neotest")
		local neotest_python = require("neotest-python")
		neotest.setup({
			adapters = {
				neotest_python({
					dap = { justMyCode = false },
					args = { "--log-level", "DEBUG" },
					runner = "pytest",
					-- !!EXPERIMENTAL!! Enable shelling out to `pytest` to discover test
					-- instances for files containing a parametrize mark (default: false)
					pytest_discover_instances = true,
				}),
			},
		})
	end,
}
