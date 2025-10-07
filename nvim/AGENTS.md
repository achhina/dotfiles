# Claude AI Testing Standards for Neovim Configuration

**MANDATORY**: Every Neovim configuration change must be verified with appropriate tests following these standards.

> 📖 **MANDATORY: Use DEBUG.md for all testing, tracing, and observability. Follow the baseline → fix → verify strategy below.**

## Core Testing Protocol

### The Change Strategy

1. **Create baseline test** - Use DEBUG.md to identify appropriate observability tools and write a test that captures the current issue
2. **Make targeted fix** - Change only one configuration aspect per commit
3. **Run same test** - Execute identical test to verify the fix resolved the issue

All specific testing commands, observability tools, and debugging workflows are documented in DEBUG.md.

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
