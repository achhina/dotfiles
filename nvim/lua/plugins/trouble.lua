return {
	"folke/trouble.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	cmd = "Trouble",
	opts = {
		focus = true, -- Focus the window when opened
		follow = true, -- Follow the cursor
		preview = {
			type = "float",
			relative = "editor",
			border = "rounded",
			title = "Preview",
			title_pos = "center",
			size = { width = 0.6, height = 0.4 },
			zindex = 200,
		},
		modes = {
			-- Enhanced diagnostics mode with floating preview
			diagnostics = {
				preview = {
					type = "float",
					relative = "editor",
					border = "rounded",
					title = "Preview",
					title_pos = "center",
					size = { width = 0.6, height = 0.4 },
					zindex = 200,
				},
			},
			-- Enhanced symbols mode with floating preview
			symbols = {
				preview = {
					type = "float",
					relative = "editor",
					border = "rounded",
					title = "Preview",
					title_pos = "center",
					size = { width = 0.6, height = 0.4 },
					zindex = 200,
				},
			},
			-- Enhanced LSP mode with floating preview
			lsp = {
				preview = {
					type = "float",
					relative = "editor",
					border = "rounded",
					title = "Preview",
					title_pos = "center",
					size = { width = 0.6, height = 0.4 },
					zindex = 200,
				},
			},
			-- Enhanced quickfix mode with floating preview
			qflist = {
				preview = {
					type = "float",
					relative = "editor",
					border = "rounded",
					title = "Preview",
					title_pos = "center",
					size = { width = 0.6, height = 0.4 },
					zindex = 200,
				},
			},
		},
	},
	keys = {
		{
			"<leader>xx",
			"<cmd>Trouble diagnostics toggle<cr>",
			desc = "Diagnostics (Trouble)",
		},
		{
			"<leader>xX",
			"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
			desc = "Buffer Diagnostics (Trouble)",
		},
		{
			"<leader>cs",
			"<cmd>Trouble symbols toggle focus=false<cr>",
			desc = "Symbols (Trouble)",
		},
		{
			"<leader>cl",
			"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
			desc = "LSP Definitions / references / ... (Trouble)",
		},
		{
			"<leader>xL",
			"<cmd>Trouble loclist toggle<cr>",
			desc = "Location List (Trouble)",
		},
		{
			"<leader>xQ",
			"<cmd>Trouble qflist toggle<cr>",
			desc = "Quickfix List (Trouble)",
		},

		-- Trouble navigation (when in Trouble window)
		{
			"]t",
			function()
				if vim.bo.filetype == "trouble" then
					require("trouble").next()
				else
					-- Traditional quickfix navigation
					local qf_list = vim.fn.getqflist()
					if #qf_list == 0 then
						vim.notify("No quickfix items", vim.log.levels.WARN)
						return
					end
					local ok = pcall(vim.cmd, "cnext")
					if not ok then
						vim.cmd("cfirst")
						vim.notify("Wrapped to first quickfix item", vim.log.levels.INFO)
					end
				end
			end,
			desc = "Next item (Trouble or quickfix)",
		},
		{
			"[t",
			function()
				if vim.bo.filetype == "trouble" then
					require("trouble").prev()
				else
					-- Traditional quickfix navigation
					local qf_list = vim.fn.getqflist()
					if #qf_list == 0 then
						vim.notify("No quickfix items", vim.log.levels.WARN)
						return
					end
					local ok = pcall(vim.cmd, "cprev")
					if not ok then
						vim.cmd("clast")
						vim.notify("Wrapped to last quickfix item", vim.log.levels.INFO)
					end
				end
			end,
			desc = "Previous item (Trouble or quickfix)",
		},
	},
}
