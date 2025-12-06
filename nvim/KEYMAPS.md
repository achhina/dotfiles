# Neovim Keymaps

> [!WARNING]
> Work in Progress

This document explains custom keybinding decisions and how they compare to popular Neovim distributions.

## Diagnostics and Quickfix

### `<leader>q` - Quickfix-Centric Workflow

This configuration uses `<leader>q` as the **quickfix namespace**. All bindings in this namespace populate the quickfix list, enabling traditional Vim navigation commands (`:cnext`, `:cprev`, etc.) even after closing the Trouble display.

**How it works:**
Operations in the `<leader>q` namespace follow this pattern:
1. Populate the quickfix list with data (`vim.diagnostic.setqflist()` for diagnostics)
2. Display the quickfix list using Trouble (pretty UI)
3. Leave the quickfix list populated for traditional navigation

After closing Trouble, you can still use `:cnext`/`:cprev` because the quickfix list remains populated.

**Rationale:**
This is a hybrid approach combining modern UI (Trouble) with traditional Vim workflows. The `q` mnemonic represents "quickfix", and all operations in this namespace interact with the quickfix list storage.

**What other distributions do:**
- **LazyVim:** Uses only `<leader>qq` for "Quit All", leaving the rest of the `<leader>q` namespace empty. All diagnostics/quickfix operations are under `<leader>x`.
- **Kickstart.nvim:** Uses `<leader>q` for diagnostics to location list, with no other quickfix bindings.

### `<leader>x` - Direct Diagnostic Viewing (LazyVim compatibility)

Maintained for compatibility with LazyVim conventions. These bindings read directly from diagnostic sources without populating quickfix lists.

**How it works:**
Operations in the `<leader>x` namespace read directly from Neovim's diagnostic framework (`vim.diagnostic.get()`) and display results in Trouble. This provides a clean, stateless viewing experience focused on immediate diagnostic inspection.

**Rationale:**
The `x` mnemonic represents "problems/diagnostics/issues". This namespace is ideal for quick diagnostic reviews where you want to inspect issues, navigate between them in Trouble, and then close the view without side effects. No lists are persisted, keeping your session clean. LazyVim and AstroNvim users will find this familiar.

**What other distributions do:**
- **LazyVim:** This is their primary diagnostic namespace. `<leader>x` is the standard for all diagnostic operations.
- **AstroNvim:** Similar approach, using `<leader>x` for diagnostics with Trouble integration.
- **Kickstart.nvim:** Does not use `<leader>x` for diagnostics.

### Key Difference: Quickfix Persistence

**`<leader>q` (quickfix-centric):**
- Populates quickfix list
- Displays via Trouble
- `:cnext`/`:cprev` work after closing Trouble
- Traditional Vim workflow preserved

**`<leader>x` (view-only):**
- Reads directly from diagnostics
- Displays via Trouble
- No quickfix persistence
- Pure modern workflow

**When to use which:**
- Use `<leader>q` when you want traditional Vim quickfix commands (`:cnext`, `:cprev`) available after viewing
- Use `<leader>x` for a cleaner, view-only experience with no quickfix side effects
