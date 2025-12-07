# Neovim Keymaps

> [!WARNING]
> Work in Progress

This document explains custom keybinding decisions and how they compare to popular Neovim distributions.

## Documentation Structure

Each namespace section follows this template:

1. **Summary** - One-sentence description of the namespace purpose
2. **Rationale** - Why this namespace exists and when to use it
3. **Distribution comparison** - How kickstart.nvim, NvChad, LazyVim, and AstroNvim handle this

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

**Rationale:**
The `x` mnemonic represents "problems/diagnostics/issues". This namespace is ideal for quick diagnostic reviews where you want to inspect issues, navigate between them, and then close the view without side effects. No lists are persisted, keeping your session clean. LazyVim and AstroNvim users will find this familiar.

**Distribution comparison:**

| Distribution | `<leader>x` Usage |
|--------------|-------------------|
| kickstart.nvim | Not used |
| NvChad | Closes current buffer (not diagnostic-related) |
| LazyVim | Primary diagnostic namespace for workspace/buffer diagnostics, quickfix, and location lists |
| AstroNvim | Diagnostic operations with Trouble integration |
