return {
	"giuxtaposition/blink-cmp-copilot",
	dependencies = {
		"saghen/blink.cmp",
		{
			"zbirenbaum/copilot.lua",
			opts = {
				suggestion = { enabled = true, auto_trigger = true },
				panel = { enabled = true },
			},
		},
	},
}
