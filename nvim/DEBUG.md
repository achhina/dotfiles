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
| LSP not working | `:LspInfo` | Server status |
| Keymaps broken | `:verbose nmap <key>` | Source conflicts |
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
