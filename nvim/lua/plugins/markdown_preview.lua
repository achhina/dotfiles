return {
	"iamcco/markdown-preview.nvim",
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	ft = { "markdown", "md" },
	config = function()
		vim.g.mkdp_theme = "dark"
	end,
	build = function()
		vim.fn["mkdp#util#install"]()
	end,
}
