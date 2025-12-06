# Neovim Keymaps

> [!WARNING]
> Work in Progress

This document explains custom keybinding decisions and how they compare to popular Neovim distributions.

## Documentation Structure

Each namespace section follows this template:

1. **Summary** - One-sentence description of the namespace purpose
2. **How it works** - Technical explanation of operations in this namespace
3. **Rationale** - Why this namespace exists and when to use it
4. **Distribution comparison** - How LazyVim, AstroNvim, NvChad, and Kickstart.nvim handle this

### Distribution Selection Criteria

Distributions are selected based on GitHub stars (>=10k) with the `neovim-configuration` topic.

**GitHub Query:**
```bash
gh search repos 'topic:neovim-configuration' \
  --stars '>=10000' \
  --json name,stargazersCount \
  --sort stars \
  --jq '.[] | "\(.name) - \(.stargazersCount)"' \
  | cat

# Output:
# NvChad - 27553
# LazyVim - 24154
# LunarVim - 19168
# AstroNvim - 13937
```

> [!NOTE]
> We also include **kickstart.nvim** despite it lacking the `neovim-configuration` topic, as it's a widely-used starter template.

**Current results:**
- kickstart.nvim - 28,483 stars (manual inclusion)
- NvChad - 27,553 stars
- LazyVim - 24,153 stars
- LunarVim - 19,168 stars (excluded due to maintenance concerns)
- AstroNvim - 13,937 stars

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

**Distribution comparison:**
- **LazyVim:** Uses only `<leader>qq` for "Quit All", leaving the rest of the `<leader>q` namespace empty
- **AstroNvim:** Does not use `<leader>q` for diagnostics/quickfix
- **NvChad:** Uses `<leader>ds` for diagnostic location list (v2.5+), previously used `<leader>q` (v2.0)
- **Kickstart.nvim:** Uses `<leader>q` for diagnostics to location list

### `<leader>x` - Direct Diagnostic Viewing

Inspired by LazyVim conventions. These bindings read directly from diagnostic sources without populating quickfix lists.

**How it works:**
Operations in the `<leader>x` namespace read directly from Neovim's diagnostic framework (`vim.diagnostic.get()`) and display results in Trouble. This provides a clean, stateless viewing experience focused on immediate diagnostic inspection.

**Rationale:**
The `x` mnemonic represents "problems/diagnostics/issues". This namespace is ideal for quick diagnostic reviews where you want to inspect issues, navigate between them in Trouble, and then close the view without side effects. No lists are persisted, keeping your session clean. LazyVim and AstroNvim users will find this familiar.

**Distribution comparison:**
- **LazyVim:** Primary diagnostic namespace, `<leader>x` is the standard for all diagnostic operations
- **AstroNvim:** Uses `<leader>x` for diagnostics with Trouble integration
- **NvChad:** Uses `<leader>x` for closing buffers, not for diagnostics
- **Kickstart.nvim:** Does not use `<leader>x` for diagnostics

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
