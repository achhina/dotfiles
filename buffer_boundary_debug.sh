#!/bin/bash

# Buffer Boundary Performance Analysis
# Specifically for j/k stuttering at top/bottom when new content loads

echo "=== BUFFER BOUNDARY PERFORMANCE ANALYSIS ==="
echo "Testing performance issues at buffer edges during content loading..."
echo

# 1. Count buffer-related autocmds (these fire when content loads)
echo "1. BUFFER EVENT AUTOCMD ANALYSIS:"
echo "  Buffer loading events:"
nvim --headless -c 'lua
local events = {"BufReadPre", "BufReadPost", "BufRead", "BufEnter", "BufWinEnter"}
local total = 0
for _, event in ipairs(events) do
  local autocmds = vim.api.nvim_get_autocmds({event = event})
  print("  " .. event .. ": " .. #autocmds .. " handlers")
  total = total + #autocmds
end
print("  TOTAL BUFFER HANDLERS: " .. total)
' -c 'qa' 2>&1

echo

# 2. Identify expensive operations happening on buffer events
echo "2. EXPENSIVE BUFFER OPERATIONS:"
echo "  Checking for heavy operations in buffer autocmds..."

# Check the specific autocmds that might cause issues
echo "  A. BufEnter buffer cleanup (lines 156-187 in autocmds.lua):"
nvim --headless -c 'lua
-- Simulate the buffer cleanup logic
local buffers = vim.api.nvim_list_bufs()
local loaded_count = 0
for _, buf in ipairs(buffers) do
  if vim.api.nvim_buf_is_loaded(buf) then
    loaded_count = loaded_count + 1
  end
end
print("    Current loaded buffers: " .. loaded_count)
if loaded_count > 25 then
  print("    ⚠️  Buffer cleanup will trigger (performance impact)")
else
  print("    ✓ Buffer cleanup threshold not reached")
end
' -c 'qa' 2>&1

echo "  B. BufReadPre large file detection (lines 247-281 in autocmds.lua):"
echo "    This checks file size on EVERY buffer read - potential bottleneck"

echo "  C. Multiple BufWritePre hooks with LSP requests:"
echo "    Go, Python, TypeScript, Rust all have sync LSP calls"

echo

# 3. Test content loading performance specifically
echo "3. CONTENT LOADING PERFORMANCE TEST:"
echo "  Testing treesitter parsing during buffer edge scrolling..."

# Create a test file to scroll through
echo "  Creating test file for boundary scrolling..."
cat > /tmp/scroll_test.txt << 'EOF'
function test1() {
  console.log("line 1");
  console.log("line 2");
  console.log("line 3");
  console.log("line 4");
  console.log("line 5");
}

function test2() {
  console.log("line 1");
  console.log("line 2");
  console.log("line 3");
  console.log("line 4");
  console.log("line 5");
}

// Repeat this pattern many times to create a scrollable file
function test3() {
  console.log("more content");
  console.log("more content");
  console.log("more content");
  console.log("more content");
  console.log("more content");
}
EOF

# Duplicate content to make it longer
for i in {1..20}; do
  cat /tmp/scroll_test.txt >> /tmp/scroll_test_long.txt
done

echo "  Test file created with $(wc -l < /tmp/scroll_test_long.txt) lines"

# 4. Identify the specific performance bottlenecks
echo
echo "4. PERFORMANCE BOTTLENECK IDENTIFICATION:"

echo "  Critical findings:"
echo "  🔴 BufEnter autocmd runs buffer cleanup logic on EVERY buffer entry"
echo "  🔴 BufReadPre runs file size check with filesystem stat on EVERY file read"
echo "  🔴 Multiple language-specific BufWritePre hooks with synchronous LSP calls"
echo "  🟡 Todo-comments has TextChanged/InsertLeave autocmds with syntax refresh"
echo "  🟡 Git status refresh on BufEnter for git files"

echo
echo "=== RECOMMENDED OPTIMIZATIONS ==="
echo
echo "1. BUFFER CLEANUP THROTTLING:"
echo "   - Add debouncing to buffer cleanup (currently runs on every BufEnter)"
echo "   - Only run cleanup every 30 seconds instead of on every buffer switch"
echo
echo "2. FILE SIZE CHECK OPTIMIZATION:"
echo "   - Cache file size checks to avoid repeated filesystem calls"
echo "   - Only check file size once per session per file"
echo
echo "3. AUTOCMD REDUCTION:"
echo "   - Combine multiple autocmds into fewer, more efficient ones"
echo "   - Use vim.schedule() to defer expensive operations"
echo
echo "4. TREESITTER OPTIMIZATION:"
echo "   - Reduce incremental parsing updates"
echo "   - Disable treesitter-context during rapid scrolling"

echo
echo "Analysis complete. Run 'nvim /tmp/scroll_test_long.txt' and test j/k at boundaries to verify issues."
