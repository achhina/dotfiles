# Neovim Debugging Guide

Essential debugging commands for troubleshooting Neovim configuration issues.

## Core Diagnostics

### `:checkhealth`
Main diagnostic command. Shows status of all plugins and configurations.
- **Source**: `:help checkhealth`
- **Usage**: Run when encountering any configuration issues

### `:messages`
Shows all vim messages including errors and warnings.
- **Source**: `:help messages`
- **Usage**: Check for error messages after startup or plugin loading

## LSP Debugging

### `:LspInfo`
Shows status of all LSP servers for current buffer.
- **Source**: nvim-lspconfig documentation
- **Usage**: Check which LSP servers are attached and their status

### `:LspLog`
Opens LSP log file in split window.
- **Source**: nvim-lspconfig documentation
- **Usage**: View detailed LSP communication and errors

### Enable LSP Debug Logging
```lua
vim.lsp.set_log_level("DEBUG")
```
- **Source**: `:help vim.lsp`
- **Usage**: Add to init.lua temporarily for detailed LSP debugging

## Advanced Debugging

### `:verbose <command>`
Runs command with verbose output showing sourcing information.
- **Source**: `:help verbose`
- **Example**: `:verbose map <leader>` shows where keymaps are defined

### Lua Object Inspection
```lua
:lua print(vim.inspect(object))
```
- **Source**: `:help vim.inspect`
- **Usage**: Debug lua tables and objects in configuration

## Environment Variables

### `NVIM_LOG_FILE`
Set log file location for debugging.
- **Source**: `:help $NVIM_LOG_FILE`
- **Usage**: `export NVIM_LOG_FILE=/tmp/nvim.log` before starting nvim

## Quick Diagnostics Workflow

1. `:checkhealth` - Overall system check
2. `:messages` - Check for error messages
3. `:LspInfo` - LSP-specific issues
4. `:LspLog` - Detailed LSP debugging if needed
