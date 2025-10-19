return {
	"giuxtaposition/blink-cmp-copilot",
	dependencies = {
		"saghen/blink.cmp",
		{
			"zbirenbaum/copilot.lua",
			opts = function()
				-- Find Node.js from Neovim's wrapper PATH, searching only Nix store paths
				-- This ensures we use the Node.js from neovim.nix extraPackages,
				-- not project-specific versions that might be in PATH
				local node_path = nil

				-- Search PATH for the Nix-provided Node.js (from Neovim wrapper)
				local path_entries = vim.split(vim.env.PATH or "", ":")
				for _, path_entry in ipairs(path_entries) do
					-- Look for nodejs in Nix store that's part of Neovim's wrapper
					if path_entry:match("/nix/store/.*%-nodejs%-[^/]+/bin$") then
						local candidate = path_entry .. "/node"
						-- Verify it exists and is executable
						if vim.fn.executable(candidate) == 1 then
							node_path = candidate
							break
						end
					end
				end

				-- Fallback: use 'node' from PATH
				if not node_path then
					vim.notify("Warning: Could not find Nix-managed Node.js, using PATH default", vim.log.levels.WARN)
					node_path = "node"
				end

				return {
					suggestion = { enabled = true, auto_trigger = true },
					panel = { enabled = true },
					copilot_node_command = node_path,
				}
			end,
		},
	},
}
