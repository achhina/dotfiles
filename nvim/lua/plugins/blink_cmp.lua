return {
	"saghen/blink.cmp",
	dependencies = {
		"rafamadriz/friendly-snippets",
		{
			"folke/lazydev.nvim",
			ft = "lua",
			opts = {
				library = {
					{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				},
			},
		},
		{ "Saghen/blink.compat", opts = {} },
		"hrsh7th/cmp-git",
		"f3fora/cmp-spell",
		"milanglacier/minuet-ai.nvim",
	},
	version = "*",
	config = function(_, opts)
		require("blink.cmp").setup(opts)
	end,
	opts = {
		keymap = {
			preset = "super-tab",
			["<Tab>"] = {
				function(cmp)
					-- Priority 1: Snippet expansion
					if cmp.snippet_active() then
						return cmp.accept()
					end

					-- Priority 2: Completion menu
					if cmp.is_visible() then
						return cmp.select_and_accept()
					end

					-- Priority 3: Show completion menu
					return cmp.show()
				end,
				"snippet_forward",
				"fallback",
			},
		},
		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "mono",
		},
		sources = {
			default = { "lsp", "path", "snippets", "buffer", "minuet" },
			per_filetype = {
				lua = { "lsp", "path", "snippets", "buffer", "lazydev", "minuet" },
				-- Enable spell for text files
				markdown = { "lsp", "path", "snippets", "buffer", "spell" },
				text = { "lsp", "path", "snippets", "buffer", "spell" },
				gitcommit = { "lsp", "path", "snippets", "buffer", "git" },
				-- Git-related files
				gitrebase = { "git" },
				gitconfig = { "git" },
			},
			providers = {
				minuet = {
					name = "minuet",
					module = "minuet.blink",
					score_offset = 8, -- Lower than LSP, higher than buffer
					async = true,
					timeout_ms = 3000,
				},
				buffer = {
					min_keyword_length = 4,
					max_items = 5,
				},
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					score_offset = 100,
				},
				git = {
					name = "git",
					module = "blink.compat.source",
					opts = {},
				},
				spell = {
					name = "spell",
					module = "blink.compat.source",
					opts = {},
				},
			},
		},
		completion = {
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 200,
			},
			menu = {
				auto_show = false,
				border = "rounded",
				draw = {
					treesitter = { "lsp" },
				},
			},
			list = {
				selection = {
					preselect = true,
					auto_insert = true,
				},
			},
			accept = {
				auto_brackets = {
					enabled = true,
				},
			},
			ghost_text = {
				enabled = true,
			},
			trigger = {
				prefetch_on_insert = false,
			},
		},
		signature = {
			enabled = true,
			window = {
				border = "rounded",
			},
		},
		fuzzy = {
			prebuilt_binaries = {
				download = true,
			},
		},
	},
	opts_extend = { "sources.default" },
}
