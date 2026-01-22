# Neovim Integration Plugin

Integrates Neovim with Claude Code using the Model Context Protocol (MCP).

## Features

- View and switch between Neovim buffers
- Get cursor location, mode, file name, marks, registers, and visual selections
- Execute Vim commands and operations
- Leverages Vim's native text editing commands

## Setup

### 1. Start Neovim with Socket Support

Launch Neovim with a socket file:

```bash
nvim --listen /tmp/nvim
```

Or add this to your Neovim `init.lua` to always expose the socket:

```lua
-- Start RPC server on a socket file
vim.fn.serverstart("/tmp/nvim")
```

### 2. Environment Variables

- `NVIM_SOCKET_PATH`: Path to Neovim socket file (default: `/tmp/nvim`)
- `ALLOW_SHELL_COMMANDS`: Controls shell command execution through Neovim (default: `false`)

⚠️ **Security Note**: `ALLOW_SHELL_COMMANDS` is set to `false` for security. Claude Code already has extensive Bash permissions configured in `claude.nix`. Enabling shell commands through Neovim would create an unnecessary privilege escalation path that bypasses the existing permission system.

### 3. Plugin Activation

The plugin is automatically activated when Claude Code starts. The MCP server will connect to your running Neovim instance.

## MCP Tools

The plugin provides the following tools with the prefix `mcp__plugin_neovim-integration_neovim__`:

- Buffer management (view, switch)
- Cursor position and mode
- File operations
- Vim command execution

## Permissions

Add to your settings if needed:

```json
{
  "permissions": {
    "allow": [
      "mcp__plugin_neovim-integration_neovim__*"
    ]
  }
}
```

## References

- [mcp-neovim-server GitHub](https://github.com/bigcodegen/mcp-neovim-server)
- [Model Context Protocol](https://modelcontextprotocol.io/)
