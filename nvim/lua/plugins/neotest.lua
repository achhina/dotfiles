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

		-- Test keymaps
		vim.keymap.set("n", "<leader>tn", function()
			require("neotest").run.run()
		end, { desc = "Run nearest test" })

		vim.keymap.set("n", "<leader>tf", function()
			require("neotest").run.run(vim.fn.expand("%"))
		end, { desc = "Run current file tests" })

		vim.keymap.set("n", "<leader>td", function()
			require("neotest").run.run({ strategy = "dap" })
		end, { desc = "Debug nearest test" })

		vim.keymap.set("n", "<leader>tD", function()
			require("neotest").run.run({ vim.fn.expand("%"), strategy = "dap" })
		end, { desc = "Debug all tests in file" })

		vim.keymap.set("n", "<leader>ts", function()
			require("neotest").summary.toggle()
		end, { desc = "Toggle test summary" })

		vim.keymap.set("n", "<leader>to", function()
			require("neotest").output.open({ enter = true, auto_close = true })
		end, { desc = "Show test output" })

		vim.keymap.set("n", "<leader>tO", function()
			require("neotest").output_panel.toggle()
		end, { desc = "Toggle test output panel" })

		vim.keymap.set("n", "<leader>tr", function()
			require("neotest").run.run_last()
		end, { desc = "Run last test" })

		vim.keymap.set("n", "<leader>tS", function()
			require("neotest").run.stop()
		end, { desc = "Stop running tests" })
	end,
}
