return {
	-- Enhanced autocompletion with multiple sources
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		-- Snippet Engine & its associated nvim-cmp source
		{
			"L3MON4D3/LuaSnip",
			build = "make install_jsregexp",
			dependencies = {
				"rafamadriz/friendly-snippets",
			},
		},
		"saadparwaiz1/cmp_luasnip",

		-- LSP completion capabilities
		"hrsh7th/cmp-nvim-lsp",

		-- Additional completion sources
		"hrsh7th/cmp-buffer", -- Buffer completions
		"hrsh7th/cmp-path", -- Path completions
		"hrsh7th/cmp-cmdline", -- Command line completions
		"hrsh7th/cmp-nvim-lua", -- Neovim Lua API completions
		"hrsh7th/cmp-emoji", -- Emoji completions
		"hrsh7th/cmp-calc", -- Math calculations
		"f3fora/cmp-spell", -- Spell completions
		"hrsh7th/cmp-nvim-lsp-signature-help", -- Function signatures

		-- Icons for completion menu
		"onsails/lspkind.nvim",
	},
	config = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")
		local lspkind = require("lspkind")

		-- Load snippets from friendly-snippets
		require("luasnip.loaders.from_vscode").lazy_load()

		-- Enhanced luasnip configuration
		luasnip.config.setup({
			history = true,
			delete_check_events = "TextChanged",
			updateevents = "TextChanged,TextChangedI",
		})

		-- Helper function for supertab behavior
		local has_words_before = function()
			local unpack_fn = unpack or table.unpack
			local line, col = unpack_fn(vim.api.nvim_win_get_cursor(0))
			return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
		end

		cmp.setup({
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			window = {
				completion = {
					border = "rounded",
					winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
					col_offset = -3,
					side_padding = 0,
				},
				documentation = {
					border = "rounded",
					winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
				},
			},
			formatting = {
				fields = { "kind", "abbr", "menu" },
				format = lspkind.cmp_format({
					mode = "symbol_text",
					maxwidth = 50,
					ellipsis_char = "...",
					show_labelDetails = true,
					before = function(entry, vim_item)
						local menu_mapping = {
							copilot = "[Copilot]",
							nvim_lsp = "[LSP]",
							nvim_lua = "[Lua]",
							luasnip = "[Snippet]",
							buffer = "[Buffer]",
							path = "[Path]",
							emoji = "[Emoji]",
							calc = "[Calc]",
							spell = "[Spell]",
							nvim_lsp_signature_help = "[Signature]",
						}
						vim_item.menu = menu_mapping[entry.source.name] or "[" .. entry.source.name .. "]"
						return vim_item
					end,
				}),
			},
			mapping = cmp.mapping.preset.insert({
				["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
				["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.abort(),
				["<CR>"] = cmp.mapping.confirm({
					behavior = cmp.ConfirmBehavior.Replace,
					select = false, -- Only confirm if explicitly selected
				}),
				["<S-CR>"] = cmp.mapping.confirm({
					behavior = cmp.ConfirmBehavior.Replace,
					select = true, -- Select first item if none selected
				}),
				["<Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_next_item()
					elseif luasnip.expand_or_locally_jumpable() then
						luasnip.expand_or_jump()
					elseif has_words_before() then
						cmp.complete()
					else
						fallback()
					end
				end, { "i", "s" }),
				["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					elseif luasnip.locally_jumpable(-1) then
						luasnip.jump(-1)
					else
						fallback()
					end
				end, { "i", "s" }),
			}),
			sources = cmp.config.sources({
				{ name = "copilot", priority = 1100 },
				{ name = "nvim_lsp", priority = 1000 },
				{ name = "nvim_lsp_signature_help", priority = 1000 },
				{ name = "luasnip", priority = 750 },
				{ name = "nvim_lua", priority = 500 },
			}, {
				{ name = "buffer", priority = 500, keyword_length = 3 },
				{ name = "path", priority = 250 },
				{ name = "emoji", priority = 200 },
				{ name = "calc", priority = 150 },
				{ name = "spell", priority = 100, keyword_length = 4 },
			}),
			experimental = {
				ghost_text = {
					hl_group = "CmpGhostText",
				},
			},
			sorting = {
				priority_weight = 2,
				comparators = {
					cmp.config.compare.offset,
					cmp.config.compare.exact,
					cmp.config.compare.score,
					cmp.config.compare.recently_used,
					cmp.config.compare.locality,
					cmp.config.compare.kind,
					cmp.config.compare.sort_text,
					cmp.config.compare.length,
					cmp.config.compare.order,
				},
			},
		})

		-- Setup for specific filetypes
		cmp.setup.filetype("gitcommit", {
			sources = cmp.config.sources({
				{ name = "buffer" },
				{ name = "spell" },
				{ name = "emoji" },
			}),
		})

		-- Command line completion
		cmp.setup.cmdline({ "/", "?" }, {
			mapping = cmp.mapping.preset.cmdline(),
			sources = {
				{ name = "buffer" },
			},
		})

		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({
				{ name = "path" },
			}, {
				{ name = "cmdline" },
			}),
			matching = { disallow_symbol_nonprefix_matching = false },
		})

		-- Additional keymaps for snippet navigation
		vim.keymap.set({ "i", "s" }, "<C-k>", function()
			if luasnip.expand_or_jumpable() then
				luasnip.expand_or_jump()
			end
		end, { desc = "Expand or jump to next snippet placeholder" })

		vim.keymap.set({ "i", "s" }, "<C-j>", function()
			if luasnip.jumpable(-1) then
				luasnip.jump(-1)
			end
		end, { desc = "Jump to previous snippet placeholder" })
	end,
}
