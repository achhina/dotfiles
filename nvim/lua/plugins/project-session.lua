return {
	-- Project management and navigation
	{
		"ahmedkhalf/project.nvim",
		name = "project_nvim",
		event = "VeryLazy",
		config = function()
			require("project_nvim").setup({
				-- Manual mode doesn't automatically change your root directory, so you have
				-- the option to manually do so using `:ProjectRoot` command.
				manual_mode = false,

				-- Methods of detecting the root directory. **"lsp"** uses the native neovim
				-- lsp, while **"pattern"** uses vim-rooter like glob pattern matching. Here
				-- order matters: if one is not detected, the other is used as fallback. You
				-- can also delete or rearangne the detection methods.
				detection_methods = { "lsp", "pattern" },

				-- All the patterns used to detect root dir, when **"pattern"** is in
				-- detection_methods
				patterns = {
					".git",
					"_darcs",
					".hg",
					".bzr",
					".svn",
					"Makefile",
					"package.json",
					"Cargo.toml",
					"pyproject.toml",
					"setup.py",
					"go.mod",
					"flake.nix",
					"shell.nix",
					"default.nix",
					"tsconfig.json",
					"jsconfig.json",
					"webpack.config.js",
					"vite.config.js",
					"composer.json",
					"Gemfile",
				},

				-- Table of lsp clients to ignore by name
				-- eg: { "efm", ... }
				ignore_lsp = {},

				-- Don't calculate root dir on specific directories
				-- Ex: { "~/.cargo/*", ... }
				exclude_dirs = {
					"~/.cargo/*",
					"~/.local/*",
					"~/.cache/*",
					"/tmp/*",
					"/usr/*",
					"/opt/*",
				},

				-- Show hidden files in telescope
				show_hidden = false,

				-- When set to false, you will get a message when project.nvim changes your
				-- directory.
				silent_chdir = true,

				-- What scope to change the directory, valid options are
				-- * global (default)
				-- * tab
				-- * win
				scope_chdir = "global",

				-- Path where project.nvim will store the project history for use in
				-- telescope
				datapath = vim.fn.stdpath("data"),
			})

			-- Load telescope extension
			pcall(require("telescope").load_extension, "projects")
		end,
	},

	-- Advanced session management
	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		keys = {
			{
				"<leader>qs",
				function()
					require("persistence").load()
				end,
				desc = "Restore session",
			},
			{
				"<leader>ql",
				function()
					require("persistence").load({ last = true })
				end,
				desc = "Restore last session",
			},
			{
				"<leader>qd",
				function()
					require("persistence").stop()
				end,
				desc = "Don't save current session",
			},
		},
		config = function()
			require("persistence").setup({
				dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"), -- directory where session files are saved
				-- minimum number of file buffers that need to be open to save
				-- Set to 0 to always save
				need = 1,
				branch = true, -- use git branch in session name
				options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
			})

			-- Auto-save sessions
			local persistence_group = vim.api.nvim_create_augroup("Persistence", { clear = true })

			-- Save session on exit
			vim.api.nvim_create_autocmd("VimLeavePre", {
				group = persistence_group,
				callback = function()
					-- Only save session if we have buffers and we're in a project
					if #vim.fn.getbufinfo({ buflisted = 1 }) > 0 then
						require("persistence").save()
					end
				end,
			})

			-- Auto-restore session when opening nvim without arguments
			vim.api.nvim_create_autocmd("VimEnter", {
				group = persistence_group,
				callback = function()
					-- Only restore session if nvim was started without arguments
					if vim.fn.argc(-1) == 0 then
						vim.defer_fn(function()
							require("persistence").load()
						end, 100)
					end
				end,
				nested = true,
			})
		end,
	},

	-- Project-specific configurations
	{
		"klen/nvim-config-local",
		event = "BufReadPre",
		config = function()
			require("config-local").setup({
				-- Config file patterns to load (lua supported)
				config_files = { ".nvim.lua", ".nvimrc", ".exrc" },

				-- Where the plugin keeps files data
				hashfile = vim.fn.stdpath("data") .. "/config-local",

				autocommands_create = true, -- Create autocommands (VimEnter, DirectoryChanged)
				commands_create = true, -- Create commands (ConfigLocalSource, ConfigLocalEdit, ConfigLocalTrust, ConfigLocalIgnore)
				silent = false, -- Disable plugin messages (Config loaded/ignored)
				lookup_parents = false, -- Lookup config files in parent directories
			})
		end,
	},

	-- Enhanced project navigation keymaps
	{
		"nvim-telescope/telescope.nvim",
		optional = true,
		keys = {
			{
				"<leader>sp",
				function()
					require("telescope").extensions.projects.projects({})
				end,
				desc = "Search projects",
			},
			{
				"<leader>sP",
				function()
					-- Search files in all projects
					local projects = require("project_nvim").get_recent_projects()
					if #projects > 0 then
						require("telescope.builtin").find_files({
							cwd = projects[1], -- Use most recent project
							prompt_title = "Files in " .. vim.fn.fnamemodify(projects[1], ":t"),
						})
					end
				end,
				desc = "Search files in recent project",
			},
		},
	},
}
