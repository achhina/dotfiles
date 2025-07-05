return {
	-- Comprehensive Git integration for Neovim
	"tpope/vim-fugitive",
	dependencies = {
		"tpope/vim-rhubarb", -- GitHub integration
	},
	cmd = {
		"G",
		"Git",
		"Gdiffsplit",
		"Gread",
		"Gwrite",
		"Ggrep",
		"GMove",
		"GDelete",
		"GBrowse",
		"GRemove",
		"GRename",
		"Glgrep",
		"Gedit",
	},
	ft = { "fugitive" },
	config = function()
		-- Enhanced fugitive keymaps
		local function map(mode, lhs, rhs, opts)
			opts = opts or {}
			vim.keymap.set(mode, lhs, rhs, opts)
		end

		-- Git namespace
		map("n", "<leader>g", "", { desc = "+git" })

		-- Git status and operations
		map("n", "<leader>gg", "<cmd>Git<cr>", { desc = "Git status" })
		map("n", "<leader>gG", "<cmd>Git<cr>", { desc = "Git status (full screen)" })
		map("n", "<leader>gd", "<cmd>Gdiffsplit<cr>", { desc = "Git diff split" })
		map("n", "<leader>gD", "<cmd>Gdiffsplit HEAD<cr>", { desc = "Git diff split HEAD" })

		-- Git operations
		map("n", "<leader>gw", "<cmd>Gwrite<cr>", { desc = "Git add file" })
		map("n", "<leader>gr", "<cmd>Gread<cr>", { desc = "Git checkout file" })
		map("n", "<leader>gq", "<cmd>Gwq<cr>", { desc = "Git add and quit" })

		-- Git log and history
		map("n", "<leader>gl", "<cmd>Git log --oneline<cr>", { desc = "Git log" })
		map("n", "<leader>gL", "<cmd>Git log<cr>", { desc = "Git log (detailed)" })
		map("n", "<leader>gf", "<cmd>Git log --follow -- %<cr>", { desc = "Git log file history" })

		-- Git grep and search
		map("n", "<leader>gg", "<cmd>Ggrep<space>", { desc = "Git grep" })
		map("n", "<leader>gG", "<cmd>Glgrep<space>", { desc = "Git log grep" })

		-- GitHub integration (via vim-rhubarb)
		map("n", "<leader>gB", "<cmd>GBrowse<cr>", { desc = "Open in GitHub" })
		map("v", "<leader>gB", ":<C-u>'<,'>GBrowse<cr>", { desc = "Open selection in GitHub" })

		-- Conflict resolution (for merge conflicts)
		map("n", "<leader>gm", "<cmd>Git mergetool<cr>", { desc = "Git mergetool" })
		map("n", "<leader>gM", "<cmd>Git merge<cr>", { desc = "Git merge" })

		-- Branch operations
		map("n", "<leader>gco", "<cmd>Git checkout<space>", { desc = "Git checkout" })
		map("n", "<leader>gcb", "<cmd>Git checkout -b<space>", { desc = "Git checkout new branch" })
		map("n", "<leader>gp", "<cmd>Git push<cr>", { desc = "Git push" })
		map("n", "<leader>gP", "<cmd>Git pull<cr>", { desc = "Git pull" })
		map("n", "<leader>gF", "<cmd>Git fetch<cr>", { desc = "Git fetch" })

		-- Commit operations
		map("n", "<leader>gcc", "<cmd>Git commit<cr>", { desc = "Git commit" })
		map("n", "<leader>gca", "<cmd>Git commit --amend<cr>", { desc = "Git commit amend" })
		map("n", "<leader>gcA", "<cmd>Git commit --amend --no-edit<cr>", { desc = "Git commit amend no edit" })

		-- Stash operations
		map("n", "<leader>gss", "<cmd>Git stash<cr>", { desc = "Git stash" })
		map("n", "<leader>gsp", "<cmd>Git stash pop<cr>", { desc = "Git stash pop" })
		map("n", "<leader>gsl", "<cmd>Git stash list<cr>", { desc = "Git stash list" })

		-- Advanced operations
		map("n", "<leader>gR", "<cmd>Git rebase -i<space>", { desc = "Git rebase interactive" })
		map("n", "<leader>gC", "<cmd>Git cherry-pick<space>", { desc = "Git cherry-pick" })
		map("n", "<leader>gT", "<cmd>Git tag<space>", { desc = "Git tag" })

		-- Quick diff toggles
		map("n", "<leader>dt", "<cmd>diffthis<cr>", { desc = "Diff this" })
		map("n", "<leader>do", "<cmd>diffoff<cr>", { desc = "Diff off" })
		map("n", "<leader>du", "<cmd>diffupdate<cr>", { desc = "Diff update" })

		-- Fugitive-specific mappings (only in fugitive buffers)
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "fugitive",
			callback = function()
				local opts = { buffer = true }
				map("n", "<tab>", "=", opts) -- Toggle staging
				map("n", "s", "=", opts) -- Stage/unstage
				map("n", "u", "-", opts) -- Unstage
				map("n", "U", "2u", opts) -- Unstage everything
				map("n", "X", "=", opts) -- Discard change
				map("n", "o", "<CR>", opts) -- Open file
				map("n", "O", "o<Tab>", opts) -- Open file in new tab
				map("n", "p", "=", opts) -- Add/reset
				map("n", "r", "e", opts) -- Reload
			end,
		})
	end,
}
