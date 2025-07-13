return {
	"stevearc/oil.nvim",
	---@module 'oil'
	---@type oil.SetupOpts
	dependencies = { "nvim-tree/nvim-web-devicons" },
	lazy = false,
	keys = {
		{ "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
		{ "<leader>-", "<CMD>Oil --float<CR>", desc = "Open parent directory in float" },
		{ "<leader>fv", "<CMD>Oil<CR>", desc = "Open file explorer" },
	},
	config = function()
		require("oil").setup({
			-- File explorer behavior
			default_file_explorer = true,
			columns = {
				"icon",
				"permissions",
				"size",
			},
			-- Buffer-specific options
			buf_options = {
				buflisted = false,
				bufhidden = "hide",
			},
			-- Window-specific options
			win_options = {
				wrap = false,
				signcolumn = "no",
				cursorcolumn = false,
				foldcolumn = "0",
				spell = false,
				list = false,
				conceallevel = 3,
				concealcursor = "nvic",
			},
			-- Send deleted files to the OS trash instead of permanently deleting them
			delete_to_trash = true,
			-- Skip the confirmation popup for simple operations
			skip_confirm_for_simple_edits = true,
			-- Selecting a new/moved/renamed file or directory will prompt you to save changes first
			prompt_save_on_select_new_entry = true,
			-- Oil will automatically delete hidden buffers after this delay
			cleanup_delay_ms = 2000,
			lsp_file_methods = {
				-- Time to wait for LSP file operations to complete before skipping
				timeout_ms = 1000,
				-- Set to true to autosave buffers that are updated with LSP willRenameFiles
				autosave_changes = false,
			},
			-- Constrain the cursor to the editable parts of the oil buffer
			constrain_cursor = "editable",
			-- Set to true to watch the filesystem for changes and reload oil
			watch_for_changes = false,
			-- Keymaps in oil buffer
			keymaps = {
				["g?"] = "actions.show_help",
				["<CR>"] = "actions.select",
				["<C-s>"] = {
					"actions.select",
					opts = { vertical = true },
					desc = "Open the entry in a vertical split",
				},
				["<C-h>"] = false, -- Disable to avoid tmux conflicts
				["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab" },
				["<C-p>"] = "actions.preview",
				["<C-c>"] = "actions.close",
				["<C-l>"] = false, -- Disable to avoid tmux conflicts
				["-"] = "actions.parent",
				["_"] = "actions.open_cwd",
				["`"] = "actions.cd",
				["~"] = {
					"actions.cd",
					opts = { scope = "tab" },
					desc = ":tcd to the current oil directory",
				},
				["gs"] = "actions.change_sort",
				["gx"] = "actions.open_external",
				["g."] = "actions.toggle_hidden",
				["g\\"] = "actions.toggle_trash",
				-- Custom keymaps for better file operations
				["<leader>r"] = "actions.refresh",
				["<leader>y"] = {
					desc = "Copy filepath to clipboard",
					callback = function()
						local oil = require("oil")
						local entry = oil.get_cursor_entry()
						local dir = oil.get_current_dir()
						if entry and dir then
							local filepath = dir .. entry.name
							vim.fn.setreg("+", filepath)
							vim.notify("Copied: " .. filepath)
						end
					end,
				},
				["<leader>Y"] = {
					desc = "Copy filename to clipboard",
					callback = function()
						local oil = require("oil")
						local entry = oil.get_cursor_entry()
						if entry then
							vim.fn.setreg("+", entry.name)
							vim.notify("Copied: " .. entry.name)
						end
					end,
				},
			},
			-- Set to false to disable all of the above keymaps
			use_default_keymaps = true,
			view_options = {
				-- Show files and directories that start with "."
				show_hidden = false,
				-- This function defines what is considered a "hidden" file
				is_hidden_file = function(name, _bufnr)
					return vim.startswith(name, ".")
				end,
				-- This function defines what will never be shown, even when `show_hidden` is set
				is_always_hidden = function(name, _bufnr)
					local always_hidden = { "..", ".git", ".DS_Store", "__pycache__", ".pytest_cache" }
					return vim.tbl_contains(always_hidden, name)
				end,
				-- Sort file names in a more intuitive order for humans
				natural_order = true,
				-- Sort order preference
				sort = {
					{ "type", "asc" }, -- directories first
					{ "name", "asc" },
				},
			},
			-- Extra arguments to pass to SCP when moving/copying files over SSH
			extra_scp_args = {},
			-- EXPERIMENTAL support for performing file operations with git
			git = {
				-- Return true to automatically git add/mv/rm files
				add = function(_path)
					return false
				end,
				mv = function(_src_path, _dest_path)
					return false
				end,
				rm = function(_path)
					return false
				end,
			},
			-- Configuration for the floating window in oil.open_float
			float = {
				-- Padding around the floating window
				padding = 2,
				max_width = 90,
				max_height = 30,
				border = "rounded",
				win_options = {
					winblend = 0,
				},
				-- optionally override the oil buffers window title with custom function: fun(winid: integer): string
				get_win_title = nil,
				-- preview_split: Split direction: "auto", "left", "right", "above", "below".
				preview_split = "auto",
				-- This is the config that will be passed to nvim_open_win.
				-- Change values here to customize the layout
				override = function(conf)
					return conf
				end,
			},
			-- Configuration for the actions floating preview window
			preview = {
				-- Width dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
				-- min_width and max_width can be a single value or a list of mixed integer/float types.
				max_width = 0.9,
				-- min_width = {40, 0.4} means "at least 40 columns, or at least 40% of total"
				min_width = { 40, 0.4 },
				-- optionally define an integer/float for the exact width of the preview window
				width = nil,
				-- Height dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
				-- min_height and max_height can be a single value or a list of mixed integer/float types.
				max_height = 0.9,
				min_height = { 5, 0.1 },
				-- optionally define an integer/float for the exact height of the preview window
				height = nil,
				border = "rounded",
				win_options = {
					winblend = 0,
				},
				-- Whether the preview window is automatically updated when the cursor is moved
				update_on_cursor_moved = true,
			},
			-- Configuration for the floating progress window
			progress = {
				max_width = 0.9,
				min_width = { 40, 0.4 },
				width = nil,
				max_height = { 10, 0.9 },
				min_height = { 5, 0.1 },
				height = nil,
				border = "rounded",
				minimized_border = "none",
				win_options = {
					winblend = 0,
				},
			},
			-- Configuration for the floating SSH window
			ssh = {
				border = "rounded",
			},
		})

		-- Enhanced keymaps for oil operations
		vim.keymap.set("n", "<leader>-", "<CMD>Oil --float<CR>", { desc = "Open parent directory in float" })
		vim.keymap.set("n", "<leader>fv", "<CMD>Oil<CR>", { desc = "Open file explorer" })

		-- Auto-commands for better oil workflow
		local oil_group = vim.api.nvim_create_augroup("OilConfig", { clear = true })

		-- Automatically close oil when opening a file
		vim.api.nvim_create_autocmd("User", {
			pattern = "OilEnter",
			group = oil_group,
			callback = function(args)
				-- Close oil automatically if we're in a floating window
				if vim.api.nvim_win_get_config(0).relative ~= "" then
					vim.keymap.set("n", "<CR>", function()
						require("oil.actions").select.callback()
						vim.api.nvim_win_close(0, false)
					end, { buffer = args.buf })
				end
			end,
		})

		-- Hide oil buffers from buffer list and quickfix
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "oil",
			group = oil_group,
			callback = function()
				vim.opt_local.buflisted = false
			end,
		})
	end,
}
