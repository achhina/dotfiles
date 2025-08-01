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
	},
	version = "*",
	opts = {
		keymap = {
			preset = "super-tab",
		},
		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "mono",
		},
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
			per_filetype = {
				lua = { "lsp", "path", "snippets", "buffer", "lazydev" },
				-- Enable spell for text files
				markdown = { "lsp", "path", "snippets", "buffer", "spell" },
				text = { "lsp", "path", "snippets", "buffer", "spell" },
				gitcommit = { "lsp", "path", "snippets", "buffer", "git" },
				-- Git-related files
				gitrebase = { "git" },
				gitconfig = { "git" },
			},
			providers = {
				copilot = {
					name = "copilot",
					module = "blink-cmp-copilot",
					score_offset = 100,
					async = true,
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
