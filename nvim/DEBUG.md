# Neovim Testing & Debugging Guide

## Systematic Configuration Testing Methodology

### Pre-Change Baseline (Always Do First)
```vim
:checkhealth       " Document all current warnings/errors
:LspInfo          " Note active LSP servers and configurations
:messages         " Check for existing error messages
:verbose map      " Review current keymap sources
```

### Post-Change Verification (Test Every Fix)
```vim
:checkhealth       " Verify warnings/errors are resolved
:LspInfo          " Confirm LSP server changes took effect
:messages         " Check for new error messages
:LspRestart       " Restart LSP servers to test new configs
```

### Testing LSP Changes Specifically
```vim
:LspInfo                    " Before: Note active servers and configs
" Make LSP configuration changes
:LspStop <server_name>      " Stop specific server
:LspStart <server_name>     " Restart specific server
:LspInfo                    " After: Verify changes took effect
:LspLog                     " Check for errors in communication
```

## Core Diagnostics

### `:checkhealth`
Main diagnostic command. Shows status of all plugins and configurations.
- **Source**: `:help checkhealth`
- **Testing Use**: Establish baseline before changes, verify fixes after
- **Focus Areas**: Look for deprecation warnings, missing dependencies, configuration errors

### `:LspInfo`
Shows status of all LSP servers for current buffer.
- **Source**: nvim-lspconfig documentation
- **Testing Use**: Verify LSP server attachment, check for unwanted servers
- **Key Info**: Active clients, enabled configurations, attached buffers

### `:messages`
Shows all vim messages including errors and warnings.
- **Source**: `:help messages`
- **Testing Use**: Catch runtime errors that may not show in other commands

### `:LspLog`
Opens LSP log file in split window.
- **Source**: nvim-lspconfig documentation
- **Testing Use**: Debug LSP communication issues and server errors

## Advanced Debugging

### `:verbose <command>`
Runs command with verbose output showing sourcing information.
- **Source**: `:help verbose`
- **Example**: `:verbose map <leader>` shows where keymaps are defined
- **Testing Use**: Identify conflicting configurations and source files

## Keymap Debugging Methodology

### Systematic Keymap Issue Diagnosis

When keymaps aren't working as expected, follow this step-by-step approach:

#### Step 1: Check Current Keymap State
```vim
:verbose nmap <key>    " Shows exact mapping and source file
:verbose imap <key>    " For insert mode
:verbose vmap <key>    " For visual mode
:verbose tmap <key>    " For terminal mode
```
**Key Information**:
- Exact command the key maps to
- Source file where mapping was last set
- Description if available

#### Step 2: Check for Conflicts
```vim
:verbose map           " Show all mappings (can be long)
:verbose nmap          " Show only normal mode mappings
```
Look for:
- Multiple mappings to the same key
- Conflicting plugin keymaps
- Overridden default vim behaviors

#### Step 3: Test Commands Directly
```vim
:CommandName           " Test if the target command works
:echo exists(':CommandName')  " Check if command exists (returns 2 if exists)
```

#### Step 4: Minimal Configuration Test
Create a minimal config to isolate the issue:
```lua
-- /tmp/minimal_test.lua
vim.opt.runtimepath:prepend('~/.local/share/nvim/lazy/lazy.nvim')
require('lazy').setup({
  { "plugin/name", config = function()
    -- Only the essential keymap
    vim.keymap.set('n', '<key>', '<cmd>Command<cr>')
  end }
})
```
Test with: `nvim -u /tmp/minimal_test.lua`

#### Step 5: Check Plugin Loading Order
Plugin loading order affects keymap precedence:
```vim
:lua print(vim.inspect(require('lazy').plugins()))
```
Later-loading plugins can override earlier keymaps.

### Common Keymap Issues and Solutions

#### Issue: Keymap Not Working
**Systematic Diagnosis:**
1. `:verbose nmap <key>` - Check if key is mapped at all
2. `:CommandName` - Test if target command works
3. Check for conflicting plugins or configurations
4. Verify plugin is loaded: `:lua print(require('lazy').plugins()['plugin-name']._.loaded)`

#### Issue: Wrong Command Executed
**Systematic Diagnosis:**
1. `:verbose nmap <key>` - See what command is actually mapped
2. Find source file causing the override
3. Check plugin loading order
4. Look for duplicate keymap definitions

#### Issue: Keymap Inconsistent Behavior
**Common Causes:**
- Different behavior in different modes
- TTY/terminal environment issues
- Plugin-specific context requirements (like tmux-navigator)
- Buffer-local vs global keymaps

#### Real Example: Tmux Navigator Issue
**Problem**: `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` not working for tmux navigation

**Systematic Diagnosis:**
```bash
# Step 1: Check keymap state
nvim -c 'verbose nmap <C-h>' -c 'qa'

# Step 2: Test command directly
nvim -c 'TmuxNavigateLeft' -c 'qa'

# Step 3: Check tmux side
tmux list-keys | grep -E "C-[hjkl]"

# Step 4: Check TTY detection
ps -o state= -o comm= -t "$(tty)" | grep vim
```

**Resolution**: Found conflicting window navigation keymaps in `keymaps.lua` overriding tmux-navigator plugin keymaps.

### Keymap Testing Protocol

For every keymap change:
1. **Document expected behavior**: What should the key do?
2. **Test before changes**: `:verbose nmap <key>`
3. **Make targeted change**: One keymap at a time
4. **Test after changes**: `:verbose nmap <key>`
5. **Verify in relevant context**: Different modes, tmux sessions, etc.

### Lua Object Inspection
```lua
:lua print(vim.inspect(vim.lsp.get_clients()))
:lua print(vim.inspect(require('lazy').plugins()))
```
- **Source**: `:help vim.inspect`
- **Testing Use**: Inspect runtime state of plugins and LSP clients

### Enable LSP Debug Logging
```lua
vim.lsp.set_log_level("DEBUG")  -- Temporary debugging
vim.lsp.set_log_level("WARN")   -- Restore normal level
```
- **Source**: `:help vim.lsp`
- **Testing Use**: Detailed LSP communication debugging

## Configuration Change Testing Protocol

### 1. Document Current State
```bash
# Create baseline snapshot
nvim --headless -c 'checkhealth' -c 'wqall' > /tmp/baseline_health.txt
nvim --headless -c 'LspInfo' -c 'wqall' > /tmp/baseline_lsp.txt
```

### 2. Make Targeted Changes
- Change one configuration aspect at a time
- Document what you expect the change to accomplish
- Note specific observability commands to verify the change

### 3. Test Changes Immediately
```vim
:source $MYVIMRC    " Reload configuration
:checkhealth        " Compare against baseline
:LspInfo            " Verify LSP changes
:messages           " Check for new errors
```

### 4. Verify Specific Behaviors
```vim
" Test specific functionality that should be affected
" Example: If changing copilot config, test completion in insert mode
" Example: If changing LSP config, test go-to-definition
```

## Environment Variables for Testing

### `NVIM_LOG_FILE`
```bash
export NVIM_LOG_FILE=/tmp/nvim_test.log
nvim # Test configuration
# Review /tmp/nvim_test.log for errors
```

## Common Testing Scenarios

### Testing LSP Server Changes
```vim
:LspInfo                    " Before
" Change server configuration
:LspRestart                 " Apply changes
:LspInfo                    " After - verify changes
:lua print(vim.inspect(vim.lsp.get_clients())) " Detailed inspection
```

### Testing Plugin Configuration
```vim
:checkhealth <plugin_name>  " Before
" Change plugin configuration
:Lazy reload <plugin_name>  " Reload plugin
:checkhealth <plugin_name>  " After - verify changes
```

### Testing Keymap Changes
```vim
:verbose map <key>          " Before - check current mapping
" Change keymap configuration
:source $MYVIMRC           " Reload
:verbose map <key>          " After - verify new mapping
```

## Headless Testing for Automated Verification

### Why Headless Testing is Superior for Configuration Verification

Headless mode (`nvim --headless`) provides:
- **Faster execution** - No UI startup overhead
- **Isolated environment** - Tests pure configuration without UI interactions
- **Automated verification** - Can script complex test scenarios
- **Deterministic results** - No user input or timing issues
- **Real plugin loading** - All plugins load normally, just without UI

### Headless Testing Examples

#### Test LSP Server Configuration
```bash
# Test if specific LSP servers are running
nvim --headless -c 'lua
vim.defer_fn(function()
  local clients = vim.lsp.get_clients()
  print("Active LSP clients:", #clients)
  for i, client in ipairs(clients) do
    print("  " .. i .. ":", client.name, "(id:" .. client.id .. ")")
  end
  vim.cmd("qa")
end, 2000)' 2>&1
```

#### Test Plugin Configuration Loading
```bash
# Test if plugin configuration is correct
nvim --headless -c 'lua
local ok, plugin = pcall(require, "plugin_name")
if ok then
  print("Plugin loaded:", ok)
  print("Config:", vim.inspect(plugin.config or plugin._config))
else
  print("Plugin failed:", plugin)
end
vim.defer_fn(function() vim.cmd("qa") end, 500)' 2>&1
```

#### Test for Deprecation Warnings
```bash
# Capture deprecation warnings during startup
nvim --headless -c 'lua
local original_notify = vim.notify
local warnings = {}
vim.notify = function(msg, level)
  if level == vim.log.levels.WARN and msg:match("deprecated") then
    table.insert(warnings, msg)
  end
  original_notify(msg, level)
end

vim.defer_fn(function()
  print("Deprecation warnings found:")
  for i, warning in ipairs(warnings) do
    print("  " .. i .. ":", warning)
  end
  vim.cmd("qa")
end, 1000)' 2>&1
```

### Real Example: Copilot LSP Investigation

This headless test revealed that copilot.lua **always** starts an LSP server:
```bash
nvim --headless -c 'lua
local copilot = require("copilot")
print("Copilot suggestion enabled:",
  copilot._config and copilot._config.suggestion and copilot._config.suggestion.enabled)

vim.defer_fn(function()
  local clients = vim.lsp.get_clients()
  print("Copilot LSP running despite suggestion.enabled=false:", #clients > 0)
  vim.cmd("qa")
end, 2000)' 2>&1
```

**Result**: Showed that disabling `suggestion.enabled` doesn't prevent LSP server startup, correcting wrong assumptions about the architecture.

### Systematic Headless Test Template

```bash
#!/bin/bash
# Template for testing Neovim configuration changes
echo "=== Pre-Change Baseline ==="
nvim --headless -c 'BASELINE_TEST_COMMANDS_HERE' -c 'qa' 2>&1

echo "=== Making Configuration Changes ==="
# Apply your configuration changes here

echo "=== Post-Change Verification ==="
nvim --headless -c 'VERIFICATION_TEST_COMMANDS_HERE' -c 'qa' 2>&1

echo "=== Test Complete ==="
```

**Key Principle**: Always establish baseline state before making changes, then use the same observability tools to verify fixes took effect. Headless testing provides automated, deterministic verification of configuration behavior.
