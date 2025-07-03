#!/bin/bash

# Neovim Performance Measurement Script
# Based on DEBUG.md methodology

echo "=== NEOVIM PERFORMANCE ANALYSIS ==="
echo "Measuring stuttering and delay issues..."
echo

# 1. Profile startup time (per DEBUG.md section 3)
echo "1. STARTUP TIME ANALYSIS:"
nvim --startuptime /tmp/startup.log +q
echo "  Top 10 slowest startup items:"
sort -k2 -nr /tmp/startup.log | head -10
echo

# 2. Check memory usage
echo "2. MEMORY USAGE:"
nvim --headless -c 'lua print("Memory:", collectgarbage("count"), "KB")' -c 'qa' 2>&1
echo

# 3. Test CursorMoved events (likely cause of j/k stuttering)
echo "3. CURSORMOVED AUTOCMD ANALYSIS:"
echo "  Checking autocmds that trigger on cursor movement..."
nvim --headless -c 'verbose autocmd CursorMoved' -c 'qa' 2>&1 | head -20
echo

# 4. Test specific performance issues
echo "4. PERFORMANCE ISSUE TESTS:"

echo "  A. Testing dropbar update frequency (potential stuttering cause):"
nvim --headless -c 'lua
local dropbar = require("dropbar")
print("Dropbar update_debounce:", dropbar.opts and dropbar.opts.general and dropbar.opts.general.update_debounce or "not configured")
' -c 'qa' 2>&1

echo "  B. Testing treesitter context (potential delay cause):"
nvim --headless -c 'lua
local ts_context = require("treesitter-context")
local config = ts_context.get_config and ts_context.get_config() or "config not accessible"
print("Treesitter context max_lines:", type(config) == "table" and config.max_lines or "unknown")
' -c 'qa' 2>&1

echo "  C. Testing noice.nvim performance impact:"
nvim --headless -c 'lua
local noice = require("noice")
print("Noice enabled:", noice ~= nil and "yes" or "no")
' -c 'qa' 2>&1

# 5. Check for problematic autocmds
echo "5. PROBLEMATIC AUTOCMD DETECTION:"
echo "  Looking for frequent event handlers that could cause stuttering..."
nvim --headless -c 'lua
local events = {"CursorMoved", "CursorMovedI", "BufEnter", "WinEnter"}
for _, event in ipairs(events) do
  local autocmds = vim.api.nvim_get_autocmds({event = event})
  print(event .. ": " .. #autocmds .. " handlers")
end
' -c 'qa' 2>&1

echo
echo "=== RECOMMENDATIONS BASED ON FINDINGS ==="

# Count CursorMoved handlers
cursor_moved_count=$(nvim --headless -c 'lua print(#vim.api.nvim_get_autocmds({event = "CursorMoved"}))' -c 'qa' 2>&1 | grep -o '[0-9]*')

if [ "$cursor_moved_count" -gt 3 ]; then
    echo "🔴 HIGH: Too many CursorMoved handlers ($cursor_moved_count) - likely cause of j/k stuttering"
    echo "   Solution: Reduce dropbar update frequency or disable for better performance"
fi

# Check startup time
startup_max=$(head -1 /tmp/startup.log | awk '{print $2}' | cut -d. -f1)
if [ "$startup_max" -gt 100 ]; then
    echo "🟡 MEDIUM: Slow startup detected (${startup_max}ms)"
    echo "   Solution: Consider lazy loading more plugins"
fi

echo "🔧 IMMEDIATE ACTIONS:"
echo "1. Increase dropbar update_debounce from 100ms to 200ms"
echo "2. Reduce treesitter-context max_lines to 2"
echo "3. Consider disabling treesitter-context entirely for better performance"
echo "4. Profile with :profile start to identify specific slow functions"

echo
echo "Analysis complete. Results saved to /tmp/startup.log for detailed review."
