return {
	"kevinhwang91/nvim-bqf",
	dependencies = { "junegunn/fzf" },
	build = function()
		vim.fn["junegunn.fzf#install"]()
	end,
}
