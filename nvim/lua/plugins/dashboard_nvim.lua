return {
	"nvimdev/dashboard-nvim",
	event = "VimEnter",
	config = function()
		local ascii = require("ascii")
		require("dashboard").setup({
			theme = "hyper",
			config = {
				header = ascii.art.misc.krakens.sleekraken,
			},
		})
	end,
	dependencies = { { "nvim-tree/nvim-web-devicons" } },
}
