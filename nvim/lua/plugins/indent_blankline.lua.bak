return {
	-- Add indentation guides even on blank lines
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	config = function()
		local ibl = require("ibl")
		ibl.setup({
			exclude = {
				filetypes = {
					"lspinfo",
					"packer",
					"checkhealth",
					"help",
					"man",
					"dashboard",
					"",
				},
			},
		})
	end,
}
