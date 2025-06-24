# Claude AI Testing Standards for Neovim Configuration

**MANDATORY**: Every Neovim configuration change must be verified with appropriate tests following these standards.

> 📖 **See DEBUG.md for comprehensive debugging workflows and real examples**

## Core Testing Protocol

### 1. Pre-Change Baseline (ALWAYS REQUIRED)

Before making any configuration changes, establish baseline state:

```bash
# Document current state
echo "=== BASELINE: LSP Servers ==="
nvim --headless -c 'lua
vim.defer_fn(function()
  local clients = vim.lsp.get_clients()
  print("Active LSP clients:", #clients)
  for i, client in ipairs(clients) do
    print("  " .. client.name .. " (id:" .. client.id .. ")")
  end
  vim.cmd("qa")
end, 2000)' 2>&1

echo "=== BASELINE: Plugin Status ==="
nvim --headless -c 'checkhealth' -c 'qa' > /tmp/baseline_health.txt 2>&1
cat /tmp/baseline_health.txt | grep -E "(WARNING|ERROR)"

echo "=== BASELINE: Messages ==="
nvim --headless -c 'messages' -c 'qa' 2>&1 | head -20
```

### 2. Make Targeted Changes (ONE AT A TIME)

- Change only one configuration aspect per commit
- Document expected behavior change
- Specify which tests will verify the change

### 3. Post-Change Verification (MANDATORY)

Verify the change worked with same baseline commands:

```bash
echo "=== VERIFICATION: LSP Servers ==="
nvim --headless -c 'lua
vim.defer_fn(function()
  local clients = vim.lsp.get_clients()
  print("Active LSP clients:", #clients)
  for i, client in ipairs(clients) do
    print("  " .. client.name .. " (id:" .. client.id .. ")")
  end
  vim.cmd("qa")
end, 2000)' 2>&1

echo "=== VERIFICATION: Plugin Status ==="
nvim --headless -c 'checkhealth' -c 'qa' > /tmp/verification_health.txt 2>&1
diff /tmp/baseline_health.txt /tmp/verification_health.txt || echo "Changes detected in health check"

echo "=== VERIFICATION: Messages ==="
nvim --headless -c 'messages' -c 'qa' 2>&1 | head -20
```

## Specific Test Categories

### LSP Configuration Changes

**Test Template:**
```bash
#!/bin/bash
# Test LSP server configuration changes

echo "=== Testing LSP Configuration: $1 ==="
nvim --headless -c "lua
-- Test specific LSP server
local clients = vim.lsp.get_clients()
local target_server = '$1'
local found = false

for _, client in ipairs(clients) do
  if client.name == target_server then
    found = true
    print('✓ ' .. target_server .. ' LSP server is running')
    print('  - ID:', client.id)
    print('  - Root dir:', client.config.root_dir or 'unknown')
    print('  - Attached buffers:', #client.attached_buffers)
  end
end

if not found then
  print('✗ ' .. target_server .. ' LSP server not found')
end

vim.defer_fn(function() vim.cmd('qa') end, 1000)
" 2>&1
```

**Usage:** `test_lsp_server.sh jsonls`

### Plugin Configuration Changes

**Test Template:**
```bash
#!/bin/bash
# Test plugin configuration

echo "=== Testing Plugin: $1 ==="
nvim --headless -c "lua
local plugin_name = '$1'
local ok, plugin = pcall(require, plugin_name)

if ok then
  print('✓ Plugin ' .. plugin_name .. ' loaded successfully')

  -- Test plugin configuration
  local config = plugin.config or plugin._config or plugin.setup
  if config then
    print('✓ Plugin has configuration')
    print('Config type:', type(config))
  else
    print('⚠ Plugin has no visible configuration')
  end

  -- Test plugin functions
  for name, func in pairs(plugin) do
    if type(func) == 'function' and not name:match('^_') then
      print('Function available:', name)
    end
  end
else
  print('✗ Failed to load plugin:', plugin)
end

vim.defer_fn(function() vim.cmd('qa') end, 500)
" 2>&1
```

**Usage:** `test_plugin.sh copilot`

### Keymap Changes

**Standard Keymap Testing Protocol:**
```bash
#!/bin/bash
# Systematic keymap testing following DEBUG.md methodology

echo "=== Testing Keymap: $1 ==="

echo "Step 1: Check current keymap state"
nvim -c "verbose nmap $1" -c 'qa' 2>&1

echo "Step 2: Test target command directly (if applicable)"
if [ -n "$2" ]; then
  nvim -c "echo 'Testing command: $2'" -c "$2" -c 'qa' 2>&1
fi

echo "Step 3: Check for conflicts"
nvim --headless -c "lua
local target_key = '$1'
local maps = vim.api.nvim_get_keymap('n')
local conflicts = {}

for _, map in ipairs(maps) do
  if map.lhs == target_key then
    table.insert(conflicts, {
      key = map.lhs,
      cmd = map.rhs or '[function]',
      desc = map.desc or '[none]'
    })
  end
end

if #conflicts == 0 then
  print('✗ No mapping found for', target_key)
elseif #conflicts == 1 then
  print('✓ Single mapping found for', target_key)
  print('  Command:', conflicts[1].cmd)
  print('  Description:', conflicts[1].desc)
else
  print('⚠ Multiple mappings found for', target_key, '(potential conflict)')
  for i, conflict in ipairs(conflicts) do
    print('  ' .. i .. ':', conflict.cmd, '(' .. conflict.desc .. ')')
  end
end

vim.cmd('qa')
" 2>&1

echo "Step 4: Verify in minimal config (create /tmp/minimal_test.lua if needed)"
```

**Usage:** `test_keymap.sh '<C-h>' 'TmuxNavigateLeft'`

**Enhanced Test for Plugin Keymaps:**
```bash
#!/bin/bash
# Test plugin keymap with loading verification

echo "=== Testing Plugin Keymap: $1 for $2 ==="

echo "Pre-test: Check plugin loading"
nvim --headless -c "lua
local plugin = '$2'
local lazy = require('lazy')
local plugins = lazy.plugins()

if plugins[plugin] then
  print('✓ Plugin found:', plugin)
  print('  Loaded:', plugins[plugin]._.loaded and 'YES' or 'NO')
else
  print('✗ Plugin not found:', plugin)
end

vim.defer_fn(function() vim.cmd('qa') end, 1000)
" 2>&1

echo "Keymap test with verbose output:"
nvim -c "verbose nmap $1" -c 'qa' 2>&1
```

**Usage:** `test_plugin_keymap.sh '<C-h>' 'christoomey/vim-tmux-navigator'`

## Systematic Test Suites

### Complete Configuration Health Check

```bash
#!/bin/bash
# Comprehensive configuration test

echo "=== COMPREHENSIVE NEOVIM CONFIG TEST ==="

echo "1. LSP Servers Status:"
nvim --headless -c 'lua
vim.defer_fn(function()
  local clients = vim.lsp.get_clients()
  if #clients == 0 then
    print("  ⚠ No LSP servers running")
  else
    for _, client in ipairs(clients) do
      print("  ✓ " .. client.name)
    end
  end
  vim.cmd("qa")
end, 2000)' 2>&1

echo "2. Plugin Health:"
nvim --headless -c 'checkhealth' -c 'qa' 2>/dev/null | grep -E "(✓|✗|WARNING|ERROR)" | head -10

echo "3. Startup Messages:"
nvim --headless -c 'messages' -c 'qa' 2>&1 | grep -E "(Error|Warning)" | head -5

echo "4. Deprecation Warnings:"
nvim --headless -c 'lua
local warnings = {}
local original_notify = vim.notify
vim.notify = function(msg, level)
  if level == vim.log.levels.WARN and msg:match("deprecated") then
    table.insert(warnings, msg)
  end
  original_notify(msg, level)
end

vim.defer_fn(function()
  if #warnings == 0 then
    print("  ✓ No deprecation warnings")
  else
    for _, warning in ipairs(warnings) do
      print("  ⚠ " .. warning)
    end
  end
  vim.cmd("qa")
end, 1000)' 2>&1

echo "=== TEST COMPLETE ==="
```

## Test Verification Standards

### Expected Test Results Documentation

For every configuration change, document:

1. **What should change:**
   ```
   Expected: Copilot LSP server should not appear in :LspInfo
   Expected: vim.highlight deprecation warning should disappear
   ```

2. **How to verify:**
   ```
   Test: nvim --headless LSP client check
   Test: nvim --headless deprecation warning scan
   ```

3. **Success criteria:**
   ```
   Success: LSP client count decreases by 1
   Success: No deprecation warnings in vim.notify capture
   ```

### Failure Investigation Protocol

When tests fail:

1. **Compare baseline vs verification outputs**
2. **Run targeted investigation scripts**
3. **Document unexpected behavior**
4. **Revert changes if verification fails**

Example investigation:
```bash
# If LSP test fails, investigate why
nvim --headless -c 'lua
print("Investigating LSP failure...")
local ok, err = pcall(function()
  require("lspconfig").problematic_server.setup({})
end)
print("Setup result:", ok, err)
vim.cmd("qa")' 2>&1
```

## Commit Standards

Every commit involving Neovim configuration must include:

1. **Baseline test results** (pre-change state)
2. **Verification test results** (post-change state)
3. **Test commands used** (reproducible verification)
4. **Expected vs actual outcomes**

Example commit message:
```
Fix copilot LSP registration issue

Baseline Test:
  LSP clients: 2 (copilot, jsonls)
  Health warnings: vim.highlight deprecation

Changes Applied:
  - Disabled copilot suggestions (enabled=false)
  - Updated vim.highlight to vim.hl

Verification Test:
  LSP clients: 1 (jsonls only) ✓ Expected
  Health warnings: 0 ✓ Expected

Test Commands:
  nvim --headless -c 'lua vim.defer_fn(...)'
  nvim --headless -c 'checkhealth' -c 'qa'

Result: ✓ All tests pass, changes verified
```

## Key Principles

1. **Never commit without testing**
2. **Document expected outcomes before changing**
3. **Use same test commands for baseline and verification**
4. **Headless testing is preferred for automation**
5. **One change, one test, one commit**
6. **Revert immediately if tests fail**
