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
}
