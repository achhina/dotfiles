return {
	-- Mini.nvim - only for features that snacks doesn't provide well
	{
		"echasnovski/mini.nvim",
		config = function()
			-- Better Around/Inside textobjects (snacks doesn't have this)
			-- Examples: va), viq, daf, etc.
			require("mini.ai").setup({
				n_lines = 500,
				custom_textobjects = {
					o = require("mini.ai").gen_spec.treesitter({
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}, {}),
					f = require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
					c = require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
					t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
					d = { "%f[%d]%d+" },
					e = {
						{
							"%u[%l%d]+%f[^%l%d]",
							"%f[%S][%l%d]+%f[^%l%d]",
							"%f[%P][%l%d]+%f[^%l%d]",
							"^[%l%d]+%f[^%l%d]",
						},
						"^().*()$",
					},
					g = function()
						local from = { line = 1, col = 1 }
						local to = {
							line = vim.fn.line("$"),
							col = math.max(vim.fn.getline("$"):len(), 1),
						}
						return { from = from, to = to }
					end,
				},
			})

			-- Enhanced commenting with treesitter support (snacks doesn't have commenting)
			require("mini.comment").setup({
				options = {
					custom_commentstring = function()
						return require("ts_context_commentstring.internal").calculate_commentstring()
							or vim.bo.commentstring
					end,
				},
				mappings = {
					comment = "gc",
					comment_line = "gcc",
					comment_visual = "gc",
					textobject = "gc",
				},
			})

			-- 2-character jumping (better than flash.nvim, snacks doesn't have this)
			require("mini.jump2d").setup({
				spotter = require("mini.jump2d").gen_pattern_spotter("[%w%p]"),
				allowed_lines = {
					blank = true,
					cursor_before = true,
					cursor_at = true,
					cursor_after = true,
					fold = true,
				},
				allowed_windows = {
					current = true,
					not_current = false,
				},
				hooks = {
					before_start = function()
						vim.wo.scrolloff = 0
					end,
					after_jump = function()
						vim.wo.scrolloff = 5
					end,
				},
				mappings = {
					start_jumping = "<leader><leader>",
				},
				silent = true,
				view = {
					dim = true,
					n_steps_ahead = 0,
				},
			})

			-- Session management (snacks doesn't have sessions)
			require("mini.sessions").setup({
				autoread = false,
				autowrite = true,
				directory = vim.fn.stdpath("data") .. "/sessions",
				file = "",
				force = { read = false, write = true, delete = false },
				hooks = {
					pre = { read = nil, write = nil, delete = nil },
					post = { read = nil, write = nil, delete = nil },
				},
				verbose = { read = false, write = true, delete = true },
			})

			-- Session management keymaps
			vim.keymap.set("n", "<leader>Ss", function()
				require("mini.sessions").select()
			end, { desc = "Select session" })

			vim.keymap.set("n", "<leader>Sw", function()
				local session_name = vim.fn.input("Session name: ")
				if session_name ~= "" then
					require("mini.sessions").write(session_name)
				end
			end, { desc = "Write session" })

			vim.keymap.set("n", "<leader>Sd", function()
				require("mini.sessions").select("delete")
			end, { desc = "Delete session" })
		end,
	},
}
