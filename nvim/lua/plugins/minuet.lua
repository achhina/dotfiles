return {
	"milanglacier/minuet-ai.nvim",
	config = function()
		require("minuet").setup({
			provider = "gemini",

			provider_options = {
				gemini = {
					model = "gemini-2.0-flash",
					optional = {
						generationConfig = {
							maxOutputTokens = 256,
							-- When using `gemini-2.5-flash`, it is recommended to entirely
							-- disable thinking for faster completion retrieval.
							thinkingConfig = {
								thinkingBudget = 0,
							},
						},
						safetySettings = {
							{
								-- HARM_CATEGORY_HATE_SPEECH,
								-- HARM_CATEGORY_HARASSMENT
								-- HARM_CATEGORY_SEXUALLY_EXPLICIT
								category = "HARM_CATEGORY_DANGEROUS_CONTENT",
								-- BLOCK_NONE
								threshold = "BLOCK_ONLY_HIGH",
							},
						},
					},
				},

				-- OpenRouter (defaults handle endpoint/API key automatically)
				openai_compatible = {
					model = "mistralai/codestral-2501", -- or "google/gemini-2.0-flash-exp", "deepseek/deepseek-chat"
					optional = {
						max_tokens = 256,
						headers = {
							["HTTP-Referer"] = "https://neovim.io",
							["X-Title"] = "Neovim",
						},
					},
				},

			},

			auto_complete = true,

			blink = {
				enable_auto_complete = true,
			},

			-- Set to "debug" to see latency/throughput metrics, "warn" for normal use
			notify = "debug",
		})
	end,
}
