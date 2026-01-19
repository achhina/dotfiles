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
			local log_file = session_dir .. "/.claude-debug.log"

			local function log(msg)
				local timestamp = os.date("%Y-%m-%d %H:%M:%S")
				vim.fn.writefile({ timestamp .. " [v2] " .. msg }, log_file, "a")
			end

			local function get_state_file_path()
				local cwd = vim.fn.getcwd()
				local cwd_encoded = cwd:gsub("/", "%%")
				local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")

				if branch ~= "" and vim.v.shell_error == 0 then
					return session_dir .. "/.claude-state-" .. cwd_encoded .. "%%" .. branch
				else
					return session_dir .. "/.claude-state-" .. cwd_encoded
				end
			end

			local function get_session_id_path()
				local cwd = vim.fn.getcwd()
				local cwd_encoded = cwd:gsub("/", "%%")
				local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")

				if branch ~= "" and vim.v.shell_error == 0 then
					return session_dir .. "/.claude-session-" .. cwd_encoded .. "%%" .. branch
				else
					return session_dir .. "/.claude-session-" .. cwd_encoded
				end
			end

			-- Save Claude state before session saves
			vim.api.nvim_create_autocmd("User", {
				pattern = "PersistenceSavePre",
				group = claude_autostart_group,
				callback = function()
					log("PersistenceSavePre fired")

					-- Check if claudecode terminal is open
					local claude_open = false
					local ok, terminal = pcall(require, "claudecode.terminal")

					if ok then
						local bufnr = terminal.get_active_terminal_bufnr()
						log("Claude terminal bufnr: " .. tostring(bufnr))

						if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
							claude_open = true
							log("Claude terminal is open")
						else
							log("Claude terminal not open")
						end
					else
						log("Failed to load claudecode.terminal")
					end

					local state_file = get_state_file_path()
					log("state_file: " .. state_file)

					if claude_open then
						vim.fn.writefile({ "1" }, state_file)
						log("Saved Claude state")
					else
						vim.fn.delete(state_file)
						log("Deleted Claude state (not open)")
					end
				end,
			})

			-- Delete state file when Claude buffer is closed
			vim.api.nvim_create_autocmd("BufDelete", {
				group = claude_autostart_group,
				callback = function(args)
					if vim.bo[args.buf].buftype == "terminal" then
						local bufname = vim.api.nvim_buf_get_name(args.buf)
						if bufname:match("[Cc]laude") then
							vim.fn.delete(get_state_file_path())
						end
					end
				end,
			})

			-- Restore Claude on session load
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

					vim.cmd("tabnext 1")

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

					local ok, terminal = pcall(require, "claudecode.terminal")
					if not ok then
						return
					end

					if session_id then
						terminal.open({}, "--resume " .. vim.fn.shellescape(session_id))
					else
						terminal.open({}, "--resume")
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
							-- Emit event after persistence loads to coordinate with other plugins
							vim.api.nvim_exec_autocmds("User", { pattern = "PersistenceLoadPost" })
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
