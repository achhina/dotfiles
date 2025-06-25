return {
	"giuxtaposition/blink-cmp-copilot",
	dependencies = {
		"saghen/blink.cmp",
		{
			"zbirenbaum/copilot.lua",
			opts = {
				suggestion = { enabled = false },
				panel = { enabled = false },
			},
		},
	},
}
