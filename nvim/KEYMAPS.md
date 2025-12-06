# Neovim Keymaps

**Status:** Work in Progress

This document explains custom keybinding decisions and how they compare to popular Neovim distributions.

## Diagnostics and Quickfix

### `<leader>q` - Quickfix and Diagnostics

This configuration uses `<leader>q` as a unified namespace for both quickfix operations and diagnostics, since diagnostics populate quickfix/location lists.

**Keybindings:**
- `<leader>qd` - Workspace diagnostics (Trouble)
- `<leader>qe` - Workspace errors only (Trouble)
- `<leader>qo` - Open quickfix (Trouble)
- `<leader>qc` - Close quickfix (Trouble)
- `<leader>qD` - Diagnostics to traditional quickfix
- `<leader>qE` - Errors to traditional quickfix
- `<leader>qO` - Open traditional quickfix
- `<leader>qC` - Close traditional quickfix

**Rationale:**
The `q` namespace semantically fits both quickfix and diagnostics operations. Since Trouble unifies the quickfix/location list/diagnostics interfaces, grouping them under a single prefix is logical and reduces cognitive overhead.

**What other distributions do:**
- **LazyVim:** Uses only `<leader>qq` for "Quit All", leaving the rest of the `<leader>q` namespace empty. All diagnostics/quickfix operations are under `<leader>x`.
- **Kickstart.nvim:** Uses `<leader>q` for diagnostics to location list, with no other quickfix bindings.

### `<leader>x` - Trouble Diagnostics (LazyVim compatibility)

Maintained for compatibility with LazyVim conventions and as an alternative access pattern.

**Keybindings:**
- `<leader>xx` - Workspace diagnostics (Trouble)
- `<leader>xX` - Buffer diagnostics (Trouble)
- `<leader>xL` - Location list (Trouble)
- `<leader>xQ` - Quickfix list (Trouble)

**Rationale:**
Provides LazyVim-style keybindings for users familiar with that distribution. The `x` mnemonic represents "problems/diagnostics/issues".

**What other distributions do:**
- **LazyVim:** This is their primary diagnostic namespace. `<leader>x` is the standard for all diagnostic operations.
- **AstroNvim:** Similar approach, using `<leader>x` for diagnostics with Trouble integration.
- **Kickstart.nvim:** Does not use `<leader>x` for diagnostics.

### Overlap

There is intentional overlap between `<leader>q` and `<leader>x`:
- `<leader>qd` and `<leader>xx` both open workspace diagnostics
- `<leader>qo` and `<leader>xQ` both open quickfix

This redundancy supports muscle memory flexibility and accommodates different mental models (quickfix-centric vs diagnostics-centric).

## Configuration Hierarchy

**basedpyright settings precedence:**
1. `pyrightconfig.json` (project root) - highest priority
2. `pyproject.toml` with `[tool.basedpyright]` section
3. LSP settings (Neovim config) - only applies when no config files exist

For projects with `pyproject.toml` or `pyrightconfig.json`, diagnostic settings in the Neovim LSP config are ignored. Editor-specific settings like `inlayHints` still apply regardless.
