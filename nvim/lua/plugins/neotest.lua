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
					is_test_file = function(file_path)
						-- Only exclude certain directories, but allow all .py files
						local exclude_dirs = {
							"node_modules",
							".git",
							"__pycache__",
							"dist",
							"build",
							".tox",
						}

						-- Check if file path contains any excluded directory
						for _, dir in ipairs(exclude_dirs) do
							if string.match(file_path, "/" .. dir .. "/") then
								return false
							end
						end

						-- Allow all Python files (let pytest handle test detection)
						return string.match(file_path, "%.py$")
					end,
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

		-- Load test keymaps for supported filetypes
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "python", "javascript", "typescript", "javascriptreact", "typescriptreact", "go", "rust" },
			callback = function(args)
				-- Only load test keymaps if we're in a buffer that likely contains tests
				local bufnr = args.buf
				local filename = vim.fn.expand("%:t")

				-- Check if this looks like a test file
				local is_test_file = filename:match("test")
					or filename:match("spec")
					or filename:match("_test%.")
					or filename:match("%.test%.")

				-- Or if neotest can discover tests in this file
				local has_tests = false
				vim.schedule(function()
					-- Use neotest to check if there are discoverable tests
					local ok, tree = pcall(require("neotest").discover, { bufnr })
					if ok and tree then
						has_tests = #tree:children() > 0
					end

					-- Load test keymaps if this is a test file or has discoverable tests
					if is_test_file or has_tests then
						require("config.keymaps").load_test_keymaps(bufnr)
					end
				end)
			end,
			desc = "Load test keymaps for test files",
		})
	end,
}
