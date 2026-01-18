return {
	"milanglacier/minuet-ai.nvim",
	config = function()
		require("minuet").setup({
			-- Provider configuration
			provider = "openrouter",

			-- Cost-saving settings
			throttle = 2000, -- Wait 2s between requests (reduces API calls)
			debounce = 800, -- Wait 800ms after typing stops
			request_timeout = 5, -- Timeout after 5 seconds

			-- Context settings to reduce token usage
			context_window = 8192, -- Reasonable context size

			-- Provider-specific options
			provider_options = {
				openrouter = {
					model = "deepseek/deepseek-coder", -- Cheap and effective ($0.14/$0.28 per 1M tokens)
					api_key = os.getenv("OPENROUTER_API_KEY"),
					optional = {
						max_tokens = 512, -- Limit response length to control costs
					},
				},
			},

			-- Enable auto-completion (set to false for manual-only mode)
			auto_complete = true,

			-- Notify on errors (helpful for debugging)
			notify = "error",
		})
	end,
}
