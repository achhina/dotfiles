return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		-- Cache for better performance
		local lsp_clients_cache = {}
		local cache_time = 0

		local function lsp_clients()
			local current_time = vim.fn.localtime()
			if current_time - cache_time < 1 then -- Cache for 1 second
				return lsp_clients_cache.result or ""
			end

			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients == 0 then
				lsp_clients_cache.result = ""
			else
				-- Only show first 2 clients to avoid clutter
				local client_names = {}
				for i, client in ipairs(clients) do
					if i <= 2 then
						table.insert(client_names, client.name)
					end
				end
				local result = " " .. table.concat(client_names, ",")
				if #clients > 2 then
					result = result .. "+" .. (#clients - 2)
				end
				lsp_clients_cache.result = result
			end

			cache_time = current_time
			return lsp_clients_cache.result
		end

		local function diff_source()
			local gitsigns = vim.b.gitsigns_status_dict
			if gitsigns then
				return {
					added = gitsigns.added,
					modified = gitsigns.changed,
					removed = gitsigns.removed,
				}
			end
		end

		local function search_count()
			if vim.v.hlsearch == 0 then
				return ""
			end
			local ok, result = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 500 })
			if not ok or result.incomplete == 1 or result.total == 0 then
				return ""
			end
			if result.total == 1 then
				return " [1/1]"
			end
			return string.format(" [%d/%d]", result.current, result.total)
		end

		local function macro_recording()
			local recording_register = vim.fn.reg_recording()
			if recording_register == "" then
				return ""
			else
				return " @" .. recording_register
			end
		end

		local function word_count()
			if vim.bo.filetype == "markdown" or vim.bo.filetype == "text" then
				local words = vim.fn.wordcount().words
				return words .. " words"
			end
			return ""
		end

		require("lualine").setup({
			options = {
				theme = "tokyodark",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				globalstatus = true,
				refresh = {
					statusline = 100, -- Refresh every 100ms instead of default 1000ms
				},
			},
			sections = {
				lualine_a = {
					"mode",
					{
						macro_recording,
						color = { fg = "#ff9e64" },
					},
				},
				lualine_b = {
					"branch",
					{
						"diff",
						source = diff_source,
						symbols = { added = " ", modified = " ", removed = " " },
					},
					{
						"diagnostics",
						sources = { "nvim_diagnostic" },
						symbols = { error = " ", warn = " ", info = " ", hint = " " },
						update_in_insert = false,
					},
				},
				lualine_c = {
					{
						"filename",
						path = 1,
						shorting_target = 40,
						symbols = {
							modified = " ●",
							readonly = " ",
							unnamed = "[No Name]",
							newfile = " [New]",
						},
					},
					search_count,
				},
				lualine_x = {
					{
						require("noice").api.statusline.mode.get,
						cond = require("noice").api.statusline.mode.has,
						color = { fg = "#ff9e64" },
					},
					word_count,
					lsp_clients,
					{
						"filetype",
						icons_enabled = true,
						icon_only = true,
					},
				},
				lualine_y = { "progress" },
				lualine_z = {
					"location",
					"selectioncount",
				},
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			extensions = { "oil", "trouble", "mason", "lazy" },
		})
	end,
}
