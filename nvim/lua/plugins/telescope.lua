return {
	-- Fuzzy Finder (files, lsp, etc)
	{ "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },

	-- Fuzzy Finder Algorithm which requires local dependencies to be built.
	-- Only load if `make` is available. Make sure you have the system
	-- requirements installed.
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		-- NOTE: If you are having trouble with this installation,
		--       refer to the README for telescope-fzf-native for more instructions.
		build = "make",
		cond = function()
			return vim.fn.executable("make") == 1
		end,

		config = function()
			-- [[ Configure Telescope ]]
			-- See `:help telescope` and `:help telescope.setup()`
			require("telescope").setup({
				defaults = {
					mappings = {
						i = {
							["<C-u>"] = false,
							["<C-d>"] = false,
						},
					},
				},
			})

			-- Enable telescope fzf native, if installed
			pcall(require("telescope").load_extension, "fzf")

			-- See `:help telescope.builtin`
			vim.keymap.set(
				"n",
				"<leader>fr",
				require("telescope.builtin").oldfiles,
				{ desc = "[?] Find recently opened files" }
			)
			vim.keymap.set(
				"n",
				"<leader><space>",
				require("telescope.builtin").buffers,
				{ desc = "[ ] Find existing buffers" }
			)
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to telescope to change theme, layout, etc.
				require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			vim.keymap.set("n", "<leader>gf", require("telescope.builtin").git_files, { desc = "Search [G]it [F]iles" })
			vim.keymap.set("n", "<leader>sf", function()
				require("telescope.builtin").find_files()
			end, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>Sf", function()
				require("telescope.builtin").find_files({ hidden = true, no_ignore = true })
			end, { desc = "[S]earch [F]iles including hidden & ignored" })
			vim.keymap.set("n", "<leader>sF", function()
				require("telescope.builtin").find_files({
					cwd = require("telescope.utils").buffer_dir(),
				})
			end, { desc = "[S]earch [F]iles from buffer cwd" })
			vim.keymap.set("n", "<leader>SF", function()
				require("telescope.builtin").find_files({
					cwd = require("telescope.utils").buffer_dir(),
					hidden = true,
					no_ignore = true,
				})
			end, { desc = "[S]earch [F]iles from buffer cwd including hidden & ignored" })
			vim.keymap.set("n", "<leader>sh", require("telescope.builtin").help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set(
				"n",
				"<leader>sw",
				require("telescope.builtin").grep_string,
				{ desc = "[S]earch current [W]ord" }
			)
			vim.keymap.set("n", "<leader>sg", require("telescope.builtin").live_grep, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", "<leader>sG", function()
				require("telescope.builtin").live_grep({ cwd = require("telescope.utils").buffer_dir() })
			end, { desc = "[S]earch by [G]rep from buffer cwd" })
			vim.keymap.set(
				"n",
				"<leader>sd",
				require("telescope.builtin").diagnostics,
				{ desc = "[S]earch [D]iagnostics" }
			)

			-- Diagnostic keymaps
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
			vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
			vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

			-- Spell Check Keymaps
			vim.keymap.set(
				"n",
				"<leader>ss",
				require("telescope.builtin").spell_suggest,
				{ desc = "[S]pell [S]uggestions" }
			)
		end,
	},
}
