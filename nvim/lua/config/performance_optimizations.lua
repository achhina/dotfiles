-- Performance optimizations to eliminate major stuttering bottlenecks
-- Based on autocmd performance analysis

-- Disable expensive built-in features that cause stuttering
local function disable_expensive_features()
	-- Disable matchparen (6.64ms improvement!)
	-- This is the biggest performance bottleneck
	vim.g.loaded_matchparen = 1

	-- Reduce updatetime for better CursorHold performance
	vim.opt.updatetime = 250 -- Default is 4000ms, but too aggressive causes issues

	-- Optimize syntax settings for better performance
	vim.opt.synmaxcol = 200 -- Don't highlight very long lines
	vim.opt.redrawtime = 1500 -- Reduce redraw timeout

	-- Disable some expensive built-in plugins for .nix files
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "nix",
		callback = function()
			-- Disable additional expensive features for .nix files specifically
			vim.wo.cursorline = false -- Disable cursor line highlighting
			vim.wo.cursorcolumn = false -- Disable cursor column highlighting
			vim.opt_local.foldmethod = "manual" -- Disable automatic folding
		end,
	})

	print("Performance optimizations loaded - matchparen disabled globally")
end

-- Optimize flash.nvim (6.56ms improvement)
local function optimize_flash()
	-- Check if flash is loaded and configure it for better performance
	local ok, flash = pcall(require, "flash")
	if ok then
		flash.setup({
			modes = {
				char = {
					enabled = false, -- Disable char mode (major performance impact)
				},
				search = {
					enabled = true, -- Keep search mode but optimize
					incremental = false, -- Disable incremental for performance
				},
			},
		})
		print("Flash.nvim optimized - char mode disabled")
	end
end

-- Initialize optimizations
disable_expensive_features()

-- Delay flash optimization to ensure it's loaded
vim.defer_fn(optimize_flash, 100)

return {
	disable_expensive_features = disable_expensive_features,
	optimize_flash = optimize_flash,
}
