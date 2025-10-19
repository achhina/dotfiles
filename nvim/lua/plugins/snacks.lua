-- luacheck: globals Snacks
return {
	"folke/snacks.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	priority = 1000,
	lazy = false,
	config = function(_, opts)
		local original_vim_notify = vim.notify

		require("snacks").setup(opts)

		if opts.notifier and opts.notifier.enabled then
			---@diagnostic disable-next-line: duplicate-set-field
			vim.notify = function(msg, level, o)
				original_vim_notify(msg, level, o)
				return require("snacks").notifier.notify(msg, level, o)
			end
		end
	end,
	---@type snacks.Config
	opts = {
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
		indent = { enabled = true },
		input = {
			enabled = true,
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
		quickfile = { enabled = true },
		scope = { enabled = true },
		scroll = {
			enabled = true,
			animate = {
				duration = { step = 15, total = 250 },
				easing = "outQuart",
			},
		},
		statuscolumn = {
			enabled = true,
			left = { "mark", "sign" },
			right = { "fold", "git" },
			folds = {
				open = true,
				git_hl = false,
			},
			git = {
				patterns = { "GitSign", "MiniDiffSign" },
			},
			refresh = 50,
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
				backdrop = {
					transparent = false,
					blend = 95,
				},
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
					backdrop = {
						transparent = true,
					},
					width = 0, -- 0 = full width (special value for fullscreen)
					height = 0, -- 0 = full height (special value for fullscreen)
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
				Snacks.zen.zoom()
			end,
			desc = "Toggle Zoom",
		},
		{
			"<leader>Z",
			function()
				Snacks.zen()
			end,
			desc = "Toggle Zen Mode",
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
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				_G.dd = function(...)
					Snacks.debug.inspect(...)
				end
				_G.bt = function()
					Snacks.debug.backtrace()
				end
				vim.print = _G.dd

				vim.api.nvim_create_user_command("Dashboard", function()
					Snacks.dashboard()
				end, { desc = "Open Dashboard" })
			end,
		})
	end,
}
