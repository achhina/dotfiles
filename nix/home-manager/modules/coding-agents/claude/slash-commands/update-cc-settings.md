---
description: Update Claude Code configuration in Home Manager
argument-hint: [setting description]
---

# Task

Update Claude Code configuration settings in Home Manager modules based on user instructions.

# Instructions

1. **Parse user instructions:**
   - Understand what settings need to be changed
   - Identify the configuration category (permissions, environment, plugins, theme, model, etc.)
   - Determine which Home Manager module(s) need to be updated

2. **Locate configuration files:**
   - Primary: `${XDG_CONFIG_HOME:-$HOME/.config}/nix/home-manager/modules/coding-agents/claude/claude.nix`
   - Search for other Claude-related Home Manager modules if needed
   - Read the current configuration to understand existing values

3. **Validate changes:**
   - Ensure the requested changes are syntactically valid for Nix
   - Check that permission patterns follow the correct format
   - Verify environment variables are properly formatted
   - Confirm plugin names/sources are correct

4. **Apply changes:**
   - Use the Edit tool to modify the configuration file(s)
   - Make minimal, targeted changes
   - Preserve existing formatting and style
   - Add comments if the change requires explanation

5. **Apply with Home Manager:**
   - Run `hm switch` to apply the configuration changes
   - Wait for the command to complete successfully
   - Check for any errors or warnings in the output

6. **Verify changes:**
   - Run `git diff` to review the exact changes made
   - Confirm the changes match the user's request
   - Check that no unintended modifications occurred

7. **Commit changes:**
   - Stage only the modified configuration file(s)
   - Create a clear, descriptive commit message
   - Follow format: "Update Claude Code [setting category]: [brief description]."
   - Run `git status` to confirm the commit succeeded

# Common Settings to Update

## Permissions
- **Allow rules:** `Bash(command:*)`, `Read`, `Write`, etc.
- **Deny rules:** Block specific commands or patterns
- **Additional directories:** Paths Claude can access

## Environment Variables
- **Timeout settings:** `BASH_DEFAULT_TIMEOUT_MS`, `BASH_MAX_TIMEOUT_MS`
- **Custom environment variables:** Any ENV_VAR needed

## Plugins
- **Enable/disable plugins:** Add or remove from `enabledPlugins`
- **Add marketplaces:** Configure `extraKnownMarketplaces`
- **Plugin settings:** Update plugin-specific configuration

## General Settings
- **Model:** Change between "sonnet", "opus", etc.
- **Theme:** Switch between "dark", "light"
- **Status line:** Update command or type
- **Auto-updates:** Enable/disable automatic updates

# Examples

**Example 1: Add a permission**
User: "Add permission for curl commands"
Action: Add `"Bash(curl:*)"` to the `allow` list in `permissions`

**Example 2: Update timeout**
User: "Increase bash timeout to 10 minutes"
Action: Update `BASH_DEFAULT_TIMEOUT_MS` to `"600000"` in `env`

**Example 3: Enable a plugin**
User: "Enable the new-plugin from the custom marketplace"
Action: Add `"new-plugin@custom-marketplace" = true;` to `enabledPlugins`

**Example 4: Add additional directory**
User: "Give Claude access to my projects folder"
Action: Add `"~/projects"` to `additionalDirectories`

# Notes

- This command only updates Home Manager configuration, not runtime settings
- Changes take effect after `hm switch` completes
- Always verify changes before committing
- Use atomic commits (one logical change per commit)
- Never modify generated files directly (they're symlinks to `/nix/store/`)
- If unsure about Nix syntax, search existing configuration for similar patterns

# Error Handling

If `hm switch` fails:
1. Review the error message carefully
2. Check for Nix syntax errors in the modified file
3. Verify the configuration is valid
4. Fix the issue and run `hm switch` again
5. Do not commit until `hm switch` succeeds

Arguments: $ARGUMENTS (description of what settings to update)
