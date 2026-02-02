# Neovim Integration Plugin

Integrates Neovim with Claude Code using the Model Context Protocol (MCP).

## Features

- View and switch between Neovim buffers
- Get cursor location, mode, file name, marks, registers, and visual selections
- Execute Vim commands and operations
- Leverages Vim's native text editing commands

## Setup

### Automatic Setup (Recommended)

When you launch Claude Code from within Neovim using `claudecode.nvim`, the integration works automatically:

1. Neovim creates a unique MCP socket on startup in its temp directory
2. The socket path is passed to Claude Code via the `NVIM_MCP_SOCKET` environment variable
3. The MCP server connects to your specific Neovim instance
4. Socket is automatically cleaned up when Neovim exits

**Usage:**

```vim
<leader>ac  " Launch Claude Code (automatically connects to this Neovim instance)
```

### Multiple Neovim Instances

Each Neovim instance gets its own unique socket based on its process ID. When you launch Claude Code from a specific Neovim instance, it connects to that instance only.

### Environment Variables

- `NVIM_MCP_SOCKET`: Automatically set by Neovim to the unique socket path for this instance
- `ALLOW_SHELL_COMMANDS`: Controls shell command execution through Neovim (default: `false`)

⚠️ **Security Note**: `ALLOW_SHELL_COMMANDS` is set to `false` for security. Claude Code already has extensive Bash permissions configured in `claude.nix`. Enabling shell commands through Neovim would create an unnecessary privilege escalation path that bypasses the existing permission system.

### Plugin Activation

The plugin is automatically activated when Claude Code starts from Neovim. The MCP server connects to the Neovim instance that launched it.

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
    "allow": ["mcp__plugin_neovim-integration_neovim__*"]
  }
}
```

## References

- [mcp-neovim-server GitHub](https://github.com/bigcodegen/mcp-neovim-server)
- [Model Context Protocol](https://modelcontextprotocol.io/)
