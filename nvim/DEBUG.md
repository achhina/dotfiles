# Neovim Debugging Guide

## Emergency Triage (30 seconds)

```bash
# Editor won't start
nvim --clean
nvim --noplugin

# Editor freezes/crashes
pkill nvim; nvim --clean

# Can't save files (run inside nvim)
:w! /tmp/backup.txt
```

## Quick Diagnosis (2 minutes)

| Problem | Command | Look For |
|---------|---------|----------|
| General issues | `:checkhealth` | ❌ and ⚠️ |
| Plugin errors | `:messages` | "Error", stack traces |
| Autocmd errors (E36, etc) | `:set verbose=9` + `:messages` | Execution trace |
| Error source identification | `:verbose autocmd [event]` | Where defined |
| Startup autocmd issues | `nvim -V9verbose.log` | Detailed execution log |
| LSP not working | `:LspInfo` | Server status |
| Keymaps broken | `:verbose nmap <key>` | Source conflicts |
| Terminal mode issues | `:tmap` + `:lua print(vim.fn.mode())` | Missing terminal mappings |
| Buffer keymap conflicts | `:lua vim.print(vim.api.nvim_buf_get_keymap(0,'t'))` | Buffer-local vs global |
| Mode transition problems | `:autocmd ModeChanged` | Stuck in wrong mode |
| Slow startup | `nvim --startuptime /tmp/startup.log` | >50ms items |

## Core Debugging Commands

### Interactive Debugging
```vim
" Live inspection - use this first
:lua vim.print(vim.lsp.get_clients())
:lua vim.print(require('lazy').plugins())
:lua vim.print(vim.g)

" Test specific functionality
:lua require('plugin-name').setup()
:lua pcall(require, 'broken-plugin')
```

### System State Check
```bash
# Configuration test
nvim --headless -c 'checkhealth' -c 'qa'

# Plugin loading test
nvim --headless -c 'lua print("Plugins:", vim.tbl_count(require("lazy").plugins()))' -c 'qa'

# LSP server test
nvim --headless -c 'lua vim.defer_fn(function() print("LSP clients:", #vim.lsp.get_clients()); vim.cmd("qa") end, 2000)'
```

## Problem Classes & Solutions

### Plugin Issues
```bash
# 1. Check if plugin loaded
:lua vim.print(require('lazy').plugins()['plugin-name'])
# Alternative: :Lazy (shows loaded status)

# 2. Test manual loading
:lua require('lazy').load({plugins = {'plugin-name'}})
# Alternative: :Lazy load plugin-name

# 3. Check for errors
:messages

# 4. Nuclear option (backup first!)
cp -r ~/.local/share/nvim/lazy ~/.local/share/nvim/lazy.backup
rm -rf ~/.local/share/nvim/lazy/plugin-name
```

### LSP Problems
```bash
# 1. Check server status
:LspInfo

# 2. Check server installation
which lua-language-server
which typescript-language-server
# Or check Mason: :Mason

# 3. Restart LSP
:LspRestart

# 4. Check logs
:LspLog
```

### Performance Issues
```bash
# 1. Profile startup
nvim --startuptime /tmp/startup.log
sort -k2 -nr /tmp/startup.log | head -10

# 2. Check memory usage
:lua print("Memory:", collectgarbage("count"), "KB")

# 3. Profile specific operations
:profile start /tmp/profile.log
:profile func *
:profile file *
# do slow operation
:profile pause
:profile dump
```

### Configuration Conflicts
```bash
# 1. Check for duplicate setups
grep -r "setup" ~/.config/nvim/lua/ | grep -v "^--" | sort

# 2. Test minimal config
nvim --clean -u minimal.lua

# 3. Check keymap conflicts
:verbose nmap <key>
# Or list all: :nmap | grep "<key>"

# 4. Binary search config files
# Comment out half your config, test, repeat
```

## Autocmd Error Debugging

**Note**: Autocmd errors (like E36, CursorMoved issues) are poorly reported in Neovim. This is a known limitation (GitHub issue #18082), not a configuration problem.

### Official Neovim Methods

```bash
# 1. Enable verbose autocmd tracking
:set verbose=9
# Now every autocmd execution is logged
# Move cursor or trigger the error to see execution trace

# 2. Identify which autocmds are registered for problematic events
:verbose autocmd CursorMoved
:verbose autocmd BufWinEnter
:verbose autocmd BufEnter
# Shows where each autocmd was defined (file and line)

# 3. Clear messages and reproduce error for clean trace
:messages clear
# trigger error (cursor movement, file opening, etc.)
:messages
# Look for the last messages before error occurs

# 4. Startup autocmd debugging
nvim -V9verbose.log
# All autocmd execution logged to file - examine for problematic patterns

# 5. Debug specific autocmd groups
:verbose autocmd [GroupName]
# Shows all autocmds in a specific group and their sources
```

### Binary Search for Problematic Autocmds

When you know an autocmd is causing issues but can't identify which:

```bash
# Method 1: Disable autocmd groups systematically
:autocmd! GroupName
# Test if error disappears - if so, problem is in that group

# Method 2: Add finish statements to plugin files
# Edit ~/.config/nvim/lua/plugins/[suspect].lua
# Add 'return {}' or 'finish' at different points to narrow down

# Method 3: Plugin-by-plugin isolation
:Lazy disable plugin-name
# Restart nvim and test - binary search through plugins
```

### UI Error Specific Commands

For E36 "Not enough room" and winbar/statusline errors:

```vim
# Check current window dimensions and content
:lua print("Width:", vim.api.nvim_win_get_width(0))
:lua print("Height:", vim.api.nvim_win_get_height(0))
:lua print("Winbar:", vim.wo.winbar or "none")
:lua print("Winbar length:", #(vim.wo.winbar or ""))

# Test in different window sizes
:vertical resize 40
# trigger error
:vertical resize 120
# test if error persists
```

### Investigation Workflow Example

Based on the breadcrumbs.lua E36 issue pattern:

```bash
# 1. Reproduce error and capture verbose output
:set verbose=9
:messages clear
# move cursor or trigger error
:messages

# 2. Look for the last autocmd before error
# Example output: "autocommand <Lua 1012: ~/.config/nvim/lua/plugins/breadcrumbs.lua:26>"

# 3. Examine that specific file and line
# breadcrumbs.lua:26 was the CursorMoved autocmd setting winbar

# 4. Test in isolation
:autocmd! [group-name]  # disable suspected autocmd group
# or temporarily disable the plugin entirely

# 5. Verify fix
# error should disappear when problematic autocmd is disabled
```

## Systematic Debugging Process

### Step 1: Reproduce & Isolate
```bash
# Can you reproduce in clean config?
nvim --clean

# Can you reproduce with minimal config?
echo 'require("problem-plugin")' > /tmp/minimal.lua
nvim --clean -u /tmp/minimal.lua
# Or test specific functionality:
echo 'vim.cmd("colorscheme default"); require("plugin")' > /tmp/test.lua
```

### Step 2: Gather Information
```bash
# Capture baseline state
nvim --headless -c 'checkhealth' -c 'qa' > /tmp/health.txt
nvim --headless -c 'messages' -c 'qa' > /tmp/messages.txt
nvim --headless -c 'LspInfo' -c 'qa' > /tmp/lsp.txt
```

### Step 3: Test Solutions
```bash
# Test one change at a time
# Document what you tried
# Compare before/after states
```

### Step 4: Verify Fix
```bash
# Restart nvim completely
# Run same health checks
# Test related functionality
```

## Red Flags (Fix Immediately)

- 🔴 `Error executing lua callback` → Plugin API breakage
- 🔴 `attempt to call field 'X' (a nil value)` → Missing dependency
- 🔴 `module 'X' not found` → Plugin not installed
- 🟡 >10 deprecation warnings → API compatibility issues
- 🟡 Startup time >1 second → Performance problem
- 🟡 LSP servers restarting → Configuration conflict

## Common Issues Requiring Investigation (Not Immediate Red Flags)

**These require systematic debugging but are normal Neovim limitations:**

- 🟠 `E36: Not enough room` or escape key not working → Check `:tmap`, `:lua print(vim.fn.mode())`, and buffer filetype
- 🟠 Generic "Error detected while processing [Event] Autocommands" → Use `:verbose autocmd [Event]` to identify source
- 🟠 Plugin conflicts in tmux/terminal environments → Test window dimensions and UI plugin compatibility

**Expected Investigation Time**: 10-30 minutes using systematic debugging workflows above.

## Advanced Techniques (When Basic Fixes Fail)

### Configuration Bisection
```bash
# When you don't know what broke
git log --oneline -10
git bisect start
git bisect bad HEAD
git bisect good <last-working-commit>
# git will guide you through testing
```

### Deep LSP Debugging
```vim
# Enable debug logging
:lua vim.lsp.set_log_level("DEBUG")

# Monitor requests/responses (advanced)
:lua local original_request = vim.lsp.buf_request
vim.lsp.buf_request = function(bufnr, method, params, handler)
  print("LSP:", method, vim.inspect(params))
  return original_request(bufnr, method, params, handler)
end

# View LSP log
:LspLog
```

### Memory Leak Detection
```bash
# Track memory over time
for i in {1..10}; do
  nvim --headless -c 'lua print(collectgarbage("count"))' -c 'qa'
  sleep 1
done
```

### User Interaction Testing
```vim
# Simulate key sequences for debugging
:lua vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'x', false)

# Test plugin interactions headless
nvim --headless -c 'lua require("fzf-lua").files()' -c 'qa'
```

### Environment Testing
```bash
# Test in different environments
SSH_CONNECTION=test nvim    # Simulate remote
TERM=xterm-256color nvim    # Test terminal compatibility
DISPLAY= nvim              # Test without GUI
TMUX= nvim                 # Test outside tmux
```

## Quick Reference

### Must-Know Commands
- `:checkhealth` - First line of defense
- `:messages` - See what broke
- `:LspInfo` - LSP status
- `:verbose nmap <key>` - Find keymap conflicts
- `:lua vim.print(X)` - Inspect anything
- `:Lazy` - Plugin manager status
- `:Mason` - LSP server manager

### Common Fixes
- Restart Neovim completely (don't just `:source`)
- Clear plugin cache: `rm -rf ~/.local/share/nvim/lazy` (backup first!)
- Reset LSP: `:LspRestart`
- Test with `:lua` before changing config files
- Check file permissions: `ls -la ~/.config/nvim/`
- Update plugins: `:Lazy sync`

### When to Escalate
- Basic commands don't reveal the issue
- Problem only occurs in specific environments
- Need to understand complex plugin interactions
- Performance issues require detailed profiling

---

*Focus: Find the problem fast → Fix it → Verify it works*
