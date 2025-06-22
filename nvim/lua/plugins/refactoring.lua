return {
	-- Advanced refactoring capabilities
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		cmd = "Refactor",
		keys = {
			-- Extract function
			{
				"<leader>re",
				":Refactor extract ",
				mode = "x",
				desc = "Extract function",
			},
			{
				"<leader>rf",
				":Refactor extract_to_file ",
				mode = "x",
				desc = "Extract function to file",
			},
			-- Extract variable
			{
				"<leader>rv",
				":Refactor extract_var ",
				mode = "x",
				desc = "Extract variable",
			},
			-- Inline function
			{
				"<leader>rI",
				":Refactor inline_func",
				mode = "n",
				desc = "Inline function",
			},
			-- Inline variable
			{
				"<leader>ri",
				":Refactor inline_var",
				mode = { "n", "x" },
				desc = "Inline variable",
			},
			-- Extract block
			{
				"<leader>rb",
				":Refactor extract_block",
				mode = "n",
				desc = "Extract block",
			},
			{
				"<leader>rbf",
				":Refactor extract_block_to_file",
				mode = "n",
				desc = "Extract block to file",
			},
			-- Debug prints (language-aware)
			{
				"<leader>rp",
				function()
					require("refactoring").debug.printf({ below = false })
				end,
				mode = "n",
				desc = "Debug print",
			},
			-- Print variable
			{
				"<leader>rv",
				function()
					require("refactoring").debug.print_var()
				end,
				mode = { "x", "n" },
				desc = "Debug print variable",
			},
			-- Clean up debug prints
			{
				"<leader>rc",
				function()
					require("refactoring").debug.cleanup({})
				end,
				mode = "n",
				desc = "Clean debug prints",
			},
		},
		config = function()
			require("refactoring").setup({
				-- prompt for return type
				prompt_func_return_type = {
					go = false,
					java = false,
					cpp = false,
					c = false,
					h = false,
					hpp = false,
					cxx = false,
				},
				-- prompt for function parameters
				prompt_func_param_type = {
					go = false,
					java = false,
					cpp = false,
					c = false,
					h = false,
					hpp = false,
					cxx = false,
				},
				printf_statements = {
					-- Language-specific debug print statements
					go = {
						'fmt.Println("%s")',
					},
					javascript = {
						'console.log("%s")',
					},
					typescript = {
						'console.log("%s")',
					},
					python = {
						'print(f"%s")',
					},
					rust = {
						'println!("%s")',
					},
					lua = {
						'print("%s")',
					},
					c = {
						'printf("%s\\n")',
					},
					cpp = {
						'std::cout << "%s" << std::endl;',
					},
					java = {
						'System.out.println("%s");',
					},
				},
				print_var_statements = {
					-- Language-specific variable print statements
					go = {
						'fmt.Printf("%%+v\\n", %s)',
					},
					javascript = {
						'console.log("%s", %s)',
					},
					typescript = {
						'console.log("%s", %s)',
					},
					python = {
						'print(f"%s: {%s}")',
					},
					rust = {
						'println!("{} = {:?}", "%s", %s);',
					},
					lua = {
						'print("%s", vim.inspect(%s))',
					},
					c = {
						'printf("%s: %%d\\n", %s);',
					},
					cpp = {
						'std::cout << "%s: " << %s << std::endl;',
					},
					java = {
						'System.out.println("%s: " + %s);',
					},
				},
				-- Show code lens for refactoring opportunities
				show_success_message = true, -- shows a message with information about the refactor on success
			})

			-- Load refactoring Telescope extension if available
			pcall(require("telescope").load_extension, "refactoring")

			-- Add telescope picker for refactoring operations
			vim.keymap.set({ "n", "x" }, "<leader>rr", function()
				require("telescope").extensions.refactoring.refactors()
			end, { desc = "Refactoring menu" })

			-- Language-specific refactoring keymaps
			local function setup_language_refactoring()
				-- Python-specific refactoring
				vim.api.nvim_create_autocmd("FileType", {
					pattern = "python",
					callback = function()
						-- Extract method for Python classes
						vim.keymap.set("x", "<leader>rem", function()
							vim.ui.input({ prompt = "Method name: " }, function(method_name)
								if method_name then
									require("refactoring").refactor("Extract Function")
								end
							end)
						end, { buffer = true, desc = "Extract method" })
					end,
				})

				-- JavaScript/TypeScript specific refactoring
				vim.api.nvim_create_autocmd("FileType", {
					pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
					callback = function()
						-- Extract React component
						vim.keymap.set("x", "<leader>rec", function()
							vim.ui.input({ prompt = "Component name: " }, function(component_name)
								if component_name then
									-- Custom logic for React component extraction could go here
									require("refactoring").refactor("Extract Function")
								end
							end)
						end, { buffer = true, desc = "Extract React component" })
					end,
				})

				-- Go-specific refactoring
				vim.api.nvim_create_autocmd("FileType", {
					pattern = "go",
					callback = function()
						-- Extract interface
						vim.keymap.set("x", "<leader>rei", function()
							vim.ui.input({ prompt = "Interface name: " }, function(interface_name)
								if interface_name then
									require("refactoring").refactor("Extract Function")
								end
							end)
						end, { buffer = true, desc = "Extract interface" })
					end,
				})
			end

			setup_language_refactoring()

			-- Integration with LSP for better refactoring
			local function enhance_lsp_refactoring()
				-- Add code actions that work well with refactoring
				vim.api.nvim_create_autocmd("LspAttach", {
					callback = function(args)
						local client = vim.lsp.get_client_by_id(args.data.client_id)
						if client and client.supports_method("textDocument/codeAction") then
							-- Add buffer-local keymap for refactoring + code actions
							vim.keymap.set("n", "<leader>ra", function()
								vim.lsp.buf.code_action({
									filter = function(action)
										-- Prefer refactoring code actions
										return action.kind and vim.startswith(action.kind, "refactor")
									end,
									apply = true,
								})
							end, { buffer = args.buf, desc = "LSP refactoring actions" })
						end
					end,
				})
			end

			enhance_lsp_refactoring()

			-- Auto-save after refactoring operations
			vim.api.nvim_create_autocmd("User", {
				pattern = "RefactoringOperationPost",
				callback = function()
					-- Auto-save all modified buffers after refactoring
					vim.cmd("silent! wall")
				end,
			})
		end,
	},

	-- Enhanced LSP signature help for better refactoring context
	{
		"ray-x/lsp_signature.nvim",
		event = "LspAttach",
		config = function()
			require("lsp_signature").setup({
				bind = true, -- This is mandatory, otherwise border config won't get registered.
				handler_opts = {
					border = "rounded",
				},
				-- Floating window configuration
				floating_window = true, -- show hint in a floating window, set to false for virtual text only
				floating_window_above_cur_line = true, -- try to place the floating above the current line when possible
				floating_window_off_x = 1, -- adjust float windows x position.
				floating_window_off_y = 0, -- adjust float windows y position.
				close_timeout = 4000, -- close floating window after ms when laster parameter is entered
				fix_pos = false, -- set to true, the floating window will not auto-close until finish all parameters
				hint_enable = true, -- virtual hint enable
				hint_prefix = " ", -- Panda for parameter, NOTE: for the terminal not support emoji, might crash
				hint_scheme = "String",
				hint_inline = function()
					return false
				end, -- should the hint be inline(nvim 0.10 only)?  default false
				hi_parameter = "LspSignatureActiveParameter", -- how your parameter will be highlight
				max_height = 12, -- max height of signature floating_window
				max_width = 80, -- max_width of signature floating_window
				noice = false, -- set to true if you using noice to render markdown
				wrap = true, -- allow doc/signature text wrap inside floating_window, useful if your lsp return doc/sig is too long
				-- Automatically trigger signature help
				toggle_key = nil, -- toggle signature on and off in insert mode,  e.g. toggle_key = '<M-x>'
				select_signature_key = nil, -- cycle to next signature, e.g. '<M-n>' function overloading
				move_cursor_key = nil, -- imap, use nvim_set_current_win to move cursor between current win and floating
			})
		end,
	},
}
