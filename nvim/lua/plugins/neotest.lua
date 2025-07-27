return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		-- Language-specific adapters
		"nvim-neotest/neotest-python",
		"nvim-neotest/neotest-go",
		"rouge8/neotest-rust",
		"nvim-neotest/neotest-jest",
	},
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-python")({
					dap = { justMyCode = false },
					args = { "--log-level", "DEBUG" },
				}),
				require("neotest-go")({
					experimental = {
						test_table = true,
					},
					args = { "-count=1", "-timeout=60s" },
				}),
				require("neotest-rust")({
					args = { "--no-capture" },
				}),
				require("neotest-jest")({
					jestCommand = "npm test --",
					jestConfigFile = "jest.config.js",
					env = { CI = true },
					cwd = function()
						return vim.fn.getcwd()
					end,
				}),
			},
			discovery = {
				enabled = true,
				concurrent = 1,
				filter_dir = function(name, _, _)
					-- Exclude node_modules and other common non-test directories
					local excluded_dirs = { "node_modules", ".git", "__pycache__", "dist", "build", ".tox" }
					for _, excluded in ipairs(excluded_dirs) do
						if name == excluded then
							return false
						end
					end
					return true
				end,
			},
			running = {
				concurrent = true,
			},
			summary = {
				enabled = true,
				animated = true,
				follow = true,
				expand_errors = true,
			},
			icons = {
				expanded = "▾",
				child_prefix = "├",
				child_indent = "│",
				final_child_prefix = "╰",
				non_collapsible = "─",
				collapsed = "▸",
				passed = "✓",
				running = "🗘",
				failed = "✗",
				unknown = "?",
			},
			floating = {
				border = "rounded",
				max_height = 0.6,
				max_width = 0.6,
			},
		})
	end,
}
