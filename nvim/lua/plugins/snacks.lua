-- luacheck: globals Snacks
return {
	"folke/snacks.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons", -- for file icons
	},
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		-- Enable most snacks modules for comprehensive functionality
		bigfile = { enabled = false }, -- Disabled - using bigfile.nvim plugin instead
		dashboard = {
			enabled = true,
			preset = {
				keys = {
					{
						icon = " ",
						key = "f",
						desc = "Find File",
						action = ":lua require('fzf-lua').combine({ pickers = 'oldfiles;files' })",
					},
					{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{ icon = " ", key = "g", desc = "Find Text", action = ":lua require('fzf-lua').live_grep()" },
					{ icon = " ", key = "r", desc = "Recent Files", action = ":lua require('fzf-lua').oldfiles()" },
					{
						icon = " ",
						key = "c",
						desc = "Config",
						action = ":lua require('fzf-lua').files({cwd='" .. vim.fn.stdpath("config") .. "'})",
					},
					{
						icon = " ",
						key = "s",
						desc = "Restore Session",
						action = ":lua require('persistence').load()",
					},
					{ icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
				header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
				]],
			},
		},
		explorer = { enabled = false }, -- Keep oil.nvim as primary file explorer
		indent = { enabled = true }, -- Modern indent guides
		input = {
			enabled = true, -- Better vim.ui.input
			win = {
				keys = {
					n_esc = { "<esc>", "cancel", mode = "n" },
					i_esc = { "<esc>", "cancel", mode = "i" },
					q = "cancel",
				},
			},
		},
		picker = { enabled = false }, -- Keep fzf-lua as primary picker
		notifier = { enabled = true },
		quickfile = { enabled = true }, -- Fast file operations
		scope = { enabled = true }, -- Enhanced scope highlighting
		scroll = {
			enabled = true,
			animate = {
				duration = { step = 15, total = 250 },
				easing = "outQuart",
			},
		},
		statuscolumn = {
			enabled = true,
			left = { "mark", "sign" }, -- order of priority
			right = { "fold", "git" }, -- order of priority
			folds = {
				open = true, -- show open fold icons
				git_hl = false, -- use git sign hl for git signs
			},
			git = {
				patterns = { "GitSign", "MiniDiffSign" },
			},
			refresh = 50, -- refresh at most every 50ms
		},
		words = {
			enabled = true,
			debounce = 200,
			notify_jump = false,
			notify_end = true,
			foldopen = true,
			jumplist = true,
			modes = { "n", "i", "c" },
		},
		image = {
			enabled = true,
		},
		zen = {
			toggles = {
				dim = true,
				git_signs = false,
				mini_diff_signs = false,
				diagnostics = false,
				inlay_hints = false,
			},
			show = {
				statusline = false,
				tabline = false,
			},
			win = {
				backdrop = 0.95,
				width = 0.8,
				height = 0.8,
				options = {
					signcolumn = "no",
					number = false,
					relativenumber = false,
					cursorline = false,
					cursorcolumn = false,
					foldcolumn = "0",
					list = false,
				},
			},
			zoom = {
				toggles = {
					dim = false,
					git_signs = true,
					mini_diff_signs = true,
					diagnostics = true,
					inlay_hints = true,
				},
				show = {
					statusline = true,
					tabline = true,
				},
				win = {
					backdrop = false,
				},
			},
		},
	},
	keys = {
		-- Dashboard
		{
			"<leader>bd",
			function()
				Snacks.dashboard()
			end,
			desc = "Dashboard",
		},

		-- Zen mode
		{
			"<leader>z",
			function()
				Snacks.zen()
			end,
			desc = "Toggle Zen Mode",
		},
		{
			"<leader>Z",
			function()
				Snacks.zen.zoom()
			end,
			desc = "Toggle Zoom",
		},

		-- File operations
		{
			"<leader>.",
			function()
				Snacks.scratch()
			end,
			desc = "Toggle Scratch Buffer",
		},

		-- Git integration
		{
			"<leader>gB",
			function()
				Snacks.gitbrowse()
			end,
			desc = "Git Browse",
			mode = { "n", "v" },
		},
		{
			"<leader>gb",
			function()
				Snacks.git.blame_line()
			end,
			desc = "Git Blame Line",
		},

		-- Terminal
		{
			"<c-/>",
			function()
				Snacks.terminal()
			end,
			desc = "Toggle Terminal",
		},
		{
			"<leader>T",
			function()
				Snacks.terminal(nil, { cwd = vim.uv.cwd() })
			end,
			desc = "Terminal (cwd)",
		},
		{
			"<c-/>",
			function()
				Snacks.terminal()
			end,
			desc = "Toggle Terminal",
			mode = "t",
		},
		{
			"<c-_>",
			function()
				Snacks.terminal()
			end,
			desc = "which_key_ignore",
			mode = "t",
		},

		-- Window management
		{
			"<leader>wm",
			function()
				Snacks.win.maximize()
			end,
			desc = "Maximize Window",
		},
		{
			"<leader>wr",
			function()
				Snacks.win.restore()
			end,
			desc = "Restore Window",
		},

		-- Word highlighting
		{
			"]]",
			function()
				Snacks.words.jump(vim.v.count1)
			end,
			desc = "Next Reference",
			mode = { "n", "t" },
		},
		{
			"[[",
			function()
				Snacks.words.jump(-vim.v.count1)
			end,
			desc = "Prev Reference",
			mode = { "n", "t" },
		},

		-- Rename file
		{
			"<leader>cR",
			function()
				Snacks.rename.rename_file()
			end,
			desc = "Rename File",
		},
	},
	init = function()
		-- Store original vim.notify BEFORE Snacks can replace it
		local original_vim_notify = vim.notify

		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				-- Setup some globals for easier access
				_G.dd = function(...)
					Snacks.debug.inspect(...)
				end
				_G.bt = function()
					Snacks.debug.backtrace()
				end
				vim.print = _G.dd -- Override print with snacks debug

				-- Create dashboard command
				vim.api.nvim_create_user_command("Dashboard", function()
					Snacks.dashboard()
				end, { desc = "Open Dashboard" })

				-- Override vim.notify to call both original and Snacks
				if Snacks.config.notifier.enabled then
					vim.notify = function(msg, level, opts)
						-- Call original vim.notify (writes to :messages)
						original_vim_notify(msg, level, opts)
						-- Also call Snacks.notifier (toast popups + history)
						return Snacks.notifier.notify(msg, level, opts)
					end
				end
			end,
		})
	end,
}
