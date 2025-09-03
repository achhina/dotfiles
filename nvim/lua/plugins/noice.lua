return {
	"folke/noice.nvim",
	event = "VeryLazy",
	opts = {
		cmdline = {
			enabled = true,
			view = "cmdline_popup",
			format = {
				cmdline = { pattern = "^:", icon = "", lang = "vim" },
				search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
				search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
				filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
			},
		},
		lsp = {
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
			},
		},
		presets = {
			bottom_search = true,
			command_palette = true,
			long_message_to_split = true,
			inc_rename = false,
			lsp_doc_border = false,
		},
		routes = {
			-- Route vim.notify calls to external handler (Snacks.notifier)
			{
				filter = { event = "notify" },
				opts = { skip = true }, -- Don't display in Noice, let vim.notify handler take over
			},
			{
				filter = {
					event = "msg_show",
					any = {
						{ find = "%d+L, %d+B" },
						{ find = "; after #%d+" },
						{ find = "; before #%d+" },
						{ find = "%d fewer lines" },
						{ find = "%d more lines" },
					},
				},
				view = "mini",
			},
			-- Skip LSP progress messages entirely - let fidget handle them
			{
				filter = {
					event = "lsp",
					kind = "progress",
				},
				opts = { skip = true },
			},
			-- Suppress mode notifications (visual, insert, etc)
			{
				filter = { event = "msg_showmode" },
				opts = { skip = true },
			},
			-- Suppress deprecation warnings
			{
				filter = {
					event = "msg_show",
					any = {
						{ find = "deprecated" },
						{ find = "buf_get_clients" },
						{ find = "is_stopped" },
						{ find = "tbl_flatten" },
						{ find = "vim%.validate" },
					},
				},
				opts = { skip = true },
			},
		},
	},
	keys = {
		{ "<leader>n", "", desc = "+noice" },
		{
			"<S-Enter>",
			function()
				require("noice").redirect(vim.fn.getcmdline())
			end,
			mode = "c",
			desc = "Redirect Cmdline",
		},
		{
			"<leader>nl",
			function()
				require("noice").cmd("last")
			end,
			desc = "Noice Last Message",
		},
		{
			"<leader>nh",
			function()
				require("noice").cmd("history")
			end,
			desc = "Noice Message History",
		},
		{
			"<leader>na",
			function()
				require("noice").cmd("all")
			end,
			desc = "Noice All",
		},
		{
			"<leader>nd",
			function()
				require("noice").cmd("dismiss")
			end,
			desc = "Dismiss All",
		},
		{
			"<c-f>",
			function()
				if not require("noice.lsp").scroll(4) then
					return "<c-f>"
				end
			end,
			silent = true,
			expr = true,
			desc = "Scroll forward",
			mode = { "i", "n", "s" },
		},
		{
			"<c-b>",
			function()
				if not require("noice.lsp").scroll(-4) then
					return "<c-b>"
				end
			end,
			silent = true,
			expr = true,
			desc = "Scroll backward",
			mode = { "i", "n", "s" },
		},
	},
	dependencies = {
		"MunifTanjim/nui.nvim",
		-- Note: Using snacks.notifier instead of nvim-notify for vim.notify()
		-- but noice still needs UI components for cmdline/search/messages
	},
}
