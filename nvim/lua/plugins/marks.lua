return {
	"chentoast/marks.nvim",
	event = "VeryLazy",
	opts = {
		mappings = {
			-- Disable individual bookmark mappings to avoid overlap with generic 'm'
			set_bookmark0 = false,
			set_bookmark1 = false,
			set_bookmark2 = false,
			set_bookmark3 = false,
			set_bookmark4 = false,
			set_bookmark5 = false,
			set_bookmark6 = false,
			set_bookmark7 = false,
			set_bookmark8 = false,
			set_bookmark9 = false,
			-- Generic 'm' will handle all marks including m0-m9
		},
	},
}
