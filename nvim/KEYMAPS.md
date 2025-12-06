# Neovim Keymaps

**Status:** Work in Progress

This document explains custom keybinding decisions and how they compare to popular Neovim distributions.

## Diagnostics and Quickfix

### `<leader>q` - Quickfix-Centric Workflow

This configuration uses `<leader>q` as the **quickfix namespace**. All bindings in this namespace populate the quickfix list, enabling traditional Vim navigation commands (`:cnext`, `:cprev`, etc.) even after closing the Trouble display.

**Keybindings:**
- `<leader>qd` - Populate quickfix with workspace diagnostics, display in Trouble
- `<leader>qe` - Populate quickfix with workspace errors only, display in Trouble
- `<leader>qo` - Open quickfix (Trouble)
- `<leader>qc` - Close quickfix (Trouble)
- `<leader>qD` - Populate quickfix with diagnostics, display in traditional window
- `<leader>qE` - Populate quickfix with errors, display in traditional window
- `<leader>qO` - Open traditional quickfix window
- `<leader>qC` - Close traditional quickfix window

**How it works:**
When you press `<leader>qd`, it:
1. Populates the quickfix list with diagnostics (`vim.diagnostic.setqflist()`)
2. Displays the quickfix list using Trouble (pretty UI)
3. Leaves the quickfix list populated for traditional navigation

After closing Trouble, you can still use `:cnext`/`:cprev` because the quickfix list remains populated.

**Rationale:**
This is a hybrid approach combining modern UI (Trouble) with traditional Vim workflows. The `q` mnemonic represents "quickfix", and all operations in this namespace interact with the quickfix list storage.

**What other distributions do:**
- **LazyVim:** Uses only `<leader>qq` for "Quit All", leaving the rest of the `<leader>q` namespace empty. All diagnostics/quickfix operations are under `<leader>x`.
- **Kickstart.nvim:** Uses `<leader>q` for diagnostics to location list, with no other quickfix bindings.

### `<leader>x` - Direct Diagnostic Viewing (LazyVim compatibility)

Maintained for compatibility with LazyVim conventions. These bindings read directly from diagnostic sources without populating quickfix lists.

**Keybindings:**
- `<leader>xx` - Workspace diagnostics (Trouble, direct from `vim.diagnostic.get()`)
- `<leader>xX` - Buffer diagnostics (Trouble, direct from `vim.diagnostic.get()`)
- `<leader>xL` - Location list (Trouble)
- `<leader>xQ` - Quickfix list (Trouble)

**How it differs from `<leader>q`:**
When you press `<leader>xx`, it:
1. Opens Trouble reading directly from Neovim's diagnostic framework
2. Does NOT populate the quickfix list
3. After closing Trouble, `:cnext`/`:cprev` won't work (no quickfix data)

This is a pure viewing mode - no quickfix list persistence.

**Rationale:**
Provides LazyVim-style keybindings for users familiar with that distribution. The `x` mnemonic represents "problems/diagnostics/issues". Use this when you just want to browse diagnostics without needing traditional quickfix navigation afterward.

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

**Overlap:**
While `<leader>qd` and `<leader>xx` both display workspace diagnostics in Trouble, they differ in persistence:
- `<leader>qd` - leaves quickfix populated for traditional navigation
- `<leader>xx` - pure viewing, no quickfix side effects

Choose `<leader>q` when you want traditional Vim quickfix commands available, or `<leader>x` for a cleaner, view-only experience.

## Configuration Hierarchy

**basedpyright settings precedence:**
1. `pyrightconfig.json` (project root) - highest priority
2. `pyproject.toml` with `[tool.basedpyright]` section
3. LSP settings (Neovim config) - only applies when no config files exist

For projects with `pyproject.toml` or `pyrightconfig.json`, diagnostic settings in the Neovim LSP config are ignored. Editor-specific settings like `inlayHints` still apply regardless.
