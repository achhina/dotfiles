-- https://github.com/vimwiki/vimwiki/issues/1288#issuecomment-1477267366
return {
	"vimwiki/vimwiki",
	init = function() --replace 'config' with 'init'
		local home = os.getenv("XDG_HOME") or "~"
		vim.g.vimwiki_list = { { path = home .. "wiki", syntax = "markdown", ext = ".md" } }
	end,
}
