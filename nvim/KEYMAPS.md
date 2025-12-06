# Neovim Keymaps

> [!WARNING]
> Work in Progress

This document explains custom keybinding decisions and how they compare to popular Neovim distributions.

## Documentation Structure

Each namespace section follows this template:

1. **Summary** - One-sentence description of the namespace purpose
2. **How it works** - Technical explanation of operations in this namespace
3. **Rationale** - Why this namespace exists and when to use it
4. **Distribution comparison** - How kickstart.nvim, NvChad, LazyVim, and AstroNvim handle this

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
> **kickstart.nvim** is manually included despite lacking the `neovim-configuration` topic, as it's a widely-used starter template.
>
> **LunarVim** is excluded from comparisons. The maintainer [stated](https://github.com/LunarVim/LunarVim/discussions/4518#discussioncomment-8963843): "Since I moved to astronvim, there's no one actively working on lunarvim, so there probably won't be another release for quite a while."

**Current results (2025-12-06):**

| Distribution | Stars |
|--------------|-------|
| kickstart.nvim | 28,483 |
| NvChad | 27,553 |
| LazyVim | 24,153 |
| AstroNvim | 13,937 |

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

| Distribution | `<leader>q` Usage |
|--------------|-------------------|
| kickstart.nvim | Populates location list with diagnostics (`vim.diagnostic.setloclist`) |
| NvChad | `<leader>ds` for diagnostic location list (v2.5+); previously `<leader>q` (v2.0) |
| LazyVim | `<leader>qq` for "Quit All" only; rest of namespace unused |
| AstroNvim | Not used for diagnostics or quickfix operations |

### `<leader>x` - Direct Diagnostic Viewing

Inspired by LazyVim conventions. These bindings read directly from diagnostic sources without populating quickfix lists.

**How it works:**
Operations in the `<leader>x` namespace read directly from Neovim's diagnostic framework (`vim.diagnostic.get()`) and display results in Trouble. This provides a clean, stateless viewing experience focused on immediate diagnostic inspection.

**Rationale:**
The `x` mnemonic represents "problems/diagnostics/issues". This namespace is ideal for quick diagnostic reviews where you want to inspect issues, navigate between them in Trouble, and then close the view without side effects. No lists are persisted, keeping your session clean. LazyVim and AstroNvim users will find this familiar.

**Distribution comparison:**

| Distribution | `<leader>x` Usage |
|--------------|-------------------|
| kickstart.nvim | Not used |
| NvChad | Closes current buffer (not diagnostic-related) |
| LazyVim | Primary diagnostic namespace for workspace/buffer diagnostics, quickfix, and location lists |
| AstroNvim | Diagnostic operations with Trouble integration |

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
