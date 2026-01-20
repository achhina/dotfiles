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
				manual_mode = true, -- Prevent automatic cwd changes that can disrupt LSP

				-- Methods of detecting the root directory. **"lsp"** uses the native neovim
				-- lsp, while **"pattern"** uses vim-rooter like glob pattern matching. Here
				-- order matters: if one is not detected, the other is used as fallback. You
				-- can also delete or rearangne the detection methods.
				detection_methods = { "pattern" }, -- Removed "lsp" to prevent LSP disconnections

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

				-- Show hidden files in project picker
				show_hidden = false,

				-- When set to false, you will get a message when project.nvim changes your
				-- directory.
				silent_chdir = true,

				-- What scope to change the directory, valid options are
				-- * global (default)
				-- * tab
				-- * win
				scope_chdir = "global",

				-- Path where project.nvim will store the project history
				datapath = vim.fn.stdpath("data"),
			})

			-- Note: project.nvim works independently, uses its own project detection
		end,
	},

	-- Advanced session management
	{
		"folke/persistence.nvim",
		dependencies = { "coder/claudecode.nvim" },
		event = "BufReadPre",
		keys = {
			{
				"<leader>Ss",
				function()
					require("persistence").load()
				end,
				desc = "Restore session",
			},
			{
				"<leader>Sl",
				function()
					require("persistence").load({ last = true })
				end,
				desc = "Restore last session",
			},
			{
				"<leader>Sd",
				function()
					require("persistence").stop()
				end,
				desc = "Don't save current session",
			},
		},
		init = function()
			-- Auto-save sessions
			-- Using init instead of config ensures autocmds are registered before VimEnter fires
			local persistence_group = vim.api.nvim_create_augroup("Persistence", { clear = true })

			-- Claude Code state tracking (must be in init to run before lazy-loading)
			local claude_autostart_group = vim.api.nvim_create_augroup("ClaudeCodeAutoStart", { clear = true })
			local session_dir = vim.fn.stdpath("state") .. "/sessions"

			-- Cache branch to avoid repeated git calls
			local _cached_branch = nil
			local _cached_cwd = nil

			local function encode_path(path)
				-- URL-style encoding for safe filesystem names
				return path:gsub("([^A-Za-z0-9_-])", function(c)
					return string.format("%%%02X", string.byte(c))
				end)
			end

			local function get_current_branch()
				local cwd = vim.fn.getcwd()
				if _cached_cwd == cwd and _cached_branch then
					return _cached_branch
				end

				_cached_cwd = cwd
				local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")
				if vim.v.shell_error == 0 and branch ~= "" then
					_cached_branch = branch
					return branch
				end
				_cached_branch = nil
				return nil
			end

			local function get_state_file_path()
				local cwd = vim.fn.getcwd()
				local cwd_encoded = encode_path(cwd)
				local branch = get_current_branch()

				if branch then
					return session_dir .. "/.claude-state-" .. cwd_encoded .. "--" .. encode_path(branch)
				else
					return session_dir .. "/.claude-state-" .. cwd_encoded
				end
			end

			local function get_session_id_path()
				local cwd = vim.fn.getcwd()
				local cwd_encoded = encode_path(cwd)
				local branch = get_current_branch()

				if branch then
					return session_dir .. "/.claude-session-" .. cwd_encoded .. "--" .. encode_path(branch)
				else
					return session_dir .. "/.claude-session-" .. cwd_encoded
				end
			end

			-- Create state file when Claude terminal opens
			vim.api.nvim_create_autocmd("TermOpen", {
				group = claude_autostart_group,
				callback = function(args)
					local bufname = vim.api.nvim_buf_get_name(args.buf)
					if bufname:match("^term://.*[Cc]laude") then
						local state_file = get_state_file_path()
						vim.fn.writefile({ "1" }, state_file)
					end
				end,
			})

			-- Delete state file when Claude buffer is closed
			vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
				group = claude_autostart_group,
				callback = function(args)
					local bufname = vim.api.nvim_buf_get_name(args.buf)
					if bufname:match("^term://.*[Cc]laude") then
						vim.fn.delete(get_state_file_path())
					end
				end,
			})

			-- Invalidate branch cache when directory changes
			vim.api.nvim_create_autocmd("DirChanged", {
				group = claude_autostart_group,
				callback = function()
					_cached_branch = nil
					_cached_cwd = nil
				end,
			})

			-- Store session info for manual restoration
			local pending_claude_restore = nil

			vim.api.nvim_create_autocmd("User", {
				pattern = "PersistenceLoadPost",
				group = claude_autostart_group,
				callback = function()
					if vim.fn.argc(-1) > 0 then
						return
					end

					local state_file = get_state_file_path()
					if vim.fn.filereadable(state_file) == 0 then
						return
					end

					local session_file = get_session_id_path()
					local session_id = nil
					if vim.fn.filereadable(session_file) == 1 then
						local ok, lines = pcall(vim.fn.readfile, session_file)
						if ok and lines and #lines > 0 then
							local raw_id = lines[1]
							if raw_id and raw_id:match("^[%w_-]+$") then
								session_id = raw_id
							end
						end
					end

					pending_claude_restore = session_id
				end,
			})

			-- Restore Claude after VimEnter when UI is fully ready
			vim.api.nvim_create_autocmd("VimEnter", {
				group = claude_autostart_group,
				callback = function()
					vim.defer_fn(function()
						if pending_claude_restore == nil then
							return
						end

						vim.cmd("tabnext 1")

						local ok, terminal = pcall(require, 'claudecode.terminal')
						if not ok then
							vim.notify("[Claude] Failed to load claudecode.terminal module", vim.log.levels.WARN)
							return
						end

						local success = pcall(function()
							if pending_claude_restore ~= false then
								terminal.simple_toggle({}, "--resume " .. vim.fn.shellescape(pending_claude_restore))
							else
								terminal.simple_toggle({}, "--resume")
							end
						end)

						if not success then
							vim.notify("[Claude] Failed to restore session", vim.log.levels.WARN)
						end

						pending_claude_restore = nil
					end, 500)
				end,
				nested = true,
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
		config = function()
			require("persistence").setup({
				dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
				need = 1,
				branch = true,
				options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
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

	-- Enhanced project navigation keymaps using fzf-lua
	{
		"ibhagwan/fzf-lua",
		optional = true,
		keys = {
			{
				"<leader>sp",
				function()
					-- Use fzf-lua to select from recent projects
					local projects = require("project_nvim").get_recent_projects()
					if #projects > 0 then
						local fzf = require("fzf-lua")
						fzf.fzf_exec(projects, {
							prompt = "Projects> ",
							actions = {
								["default"] = function(selected)
									vim.cmd("cd " .. selected[1])
								end,
							},
						})
					else
						vim.notify("No recent projects found", vim.log.levels.WARN)
					end
				end,
				desc = "Search projects",
			},
			{
				"<leader>sP",
				function()
					-- Search files in recent project
					local projects = require("project_nvim").get_recent_projects()
					if #projects > 0 then
						require("fzf-lua").files({
							cwd = projects[1],
							prompt = "Files in " .. vim.fn.fnamemodify(projects[1], ":t") .. "> ",
						})
					else
						vim.notify("No recent projects found", vim.log.levels.WARN)
					end
				end,
				desc = "Search files in recent project",
			},
		},
	},
}
