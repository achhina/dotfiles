return {
	"chentoast/marks.nvim",
	event = "VeryLazy",
	opts = {
		-- Keep all default mappings including bookmarks (m0-m9)
		-- Note: which-key will show overlap warning for 'm' with 'm0'-'m9'
		-- This is expected behavior - marks.nvim maps both the generic 'm'
		-- (for letter marks) and specific 'm0'-'m9' (for bookmarks with
		-- cross-buffer support and annotations)
	},
}
