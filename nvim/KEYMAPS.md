# Neovim Keymaps

> [!WARNING]
> Work in Progress

This document explains custom keybinding decisions and how they compare to popular Neovim distributions.

## Diagnostics and Quickfix

### `<leader>q` - Quickfix-Centric Workflow

This configuration uses `<leader>q` as the **quickfix namespace**. Operations here either populate the quickfix list or view/manipulate existing quickfix data, enabling traditional Vim navigation commands (`:cnext`, `:cprev`, etc.).

**How it works:**
The `<leader>q` namespace contains two types of operations:

1. **Population operations** (diagnostics) - populate the quickfix list with data, then display via Trouble or traditional quickfix window
2. **View operations** (open/close) - display or hide the existing quickfix list without modifying it

After using a population operation, the quickfix list remains available for traditional `:cnext`/`:cprev` navigation even after closing the display.

**Rationale:**
The `q` mnemonic represents "quickfix". This namespace centralizes all quickfix-related operations, whether populating the list with new data or viewing existing data. By maintaining quickfix list persistence, it preserves traditional Vim navigation workflows alongside modern viewing interfaces.

**What other distributions do:**
- **LazyVim:** Uses only `<leader>qq` for "Quit All", leaving the rest of the `<leader>q` namespace empty. All diagnostics/quickfix operations are under `<leader>x`.
- **Kickstart.nvim:** Uses `<leader>q` for diagnostics to location list, with no other quickfix bindings.

### `<leader>x` - Direct Diagnostic Viewing

Inspired by LazyVim conventions. These bindings read directly from diagnostic sources without populating quickfix lists.

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
