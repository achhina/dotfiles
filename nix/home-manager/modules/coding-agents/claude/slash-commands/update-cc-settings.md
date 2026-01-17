---
description: Update Claude Code configuration in Home Manager
argument-hint: [setting description]
allowed-tools:
  - Bash(worktree:*)
  - Bash(claude:*)
---

# Task

Create an isolated worktree for updating Claude Code configuration and launch a new Claude session within it to perform the updates.

# Instructions

Follow these steps:

## 1. Synthesize Worktree Name and Prompt

Based on the user's request (`$ARGUMENTS`), create:
- A short, descriptive worktree name (lowercase, hyphens, max 30 chars)
  - Example: "add-curl-permissions", "increase-bash-timeout", "enable-debugging-plugin"
- A detailed prompt for the spawned Claude session that includes:
  - The specific configuration change requested
  - Which file(s) in `nix/home-manager/modules/coding-agents/claude/` need updates
  - Instructions to run `hm switch` to apply changes
  - Instructions to verify and commit the changes

## 2. Create Worktree

Use the `worktree` CLI to create the worktree:
```bash
worktree create <synthesized-name>
```

This creates the worktree at `~/worktrees/.config/<synthesized-name>/`

## 3. Launch Claude in Worktree

Execute a new Claude session in the worktree:
```bash
cd ~/worktrees/.config/<synthesized-name> && claude -p "<detailed-prompt>"
```

The spawned Claude session will:
- Have full access to the worktree directory (it's the working directory)
- Make the requested configuration changes
- Run `hm switch` to apply the configuration
- Verify the changes with `git diff` and `git status`
- Create a well-formatted commit
- Exit when complete

## 4. Inform User

Tell the user:
- The worktree name and location
- That a new Claude session has been launched to handle the update
- How to check on progress: `cd ~/worktrees/.config/<name> && claude`
- How to clean up when done: `worktree remove <name>`

# Example

**User runs:** `/update-cc-settings Add permission for curl commands`

**You synthesize:**
- Worktree name: `add-curl-permissions`
- Prompt: `Update the Claude Code configuration in nix/home-manager/modules/coding-agents/claude/claude.nix to add "Bash(curl:*)" to the allowedTools list. After making the change, run 'hm switch' to apply it, verify with 'git diff', and create a commit with an appropriate message.`

**You execute:**
```bash
worktree create add-curl-permissions
cd ~/worktrees/.config/add-curl-permissions && claude -p "Update the Claude Code configuration in nix/home-manager/modules/coding-agents/claude/claude.nix to add \"Bash(curl:*)\" to the allowedTools list. After making the change, run 'hm switch' to apply it, verify with 'git diff', and create a commit with an appropriate message."
```

**You respond:**
```
Created worktree 'add-curl-permissions' at ~/worktrees/.config/add-curl-permissions/
Launched new Claude session to add curl permissions.

The spawned session will update the configuration, apply it, and commit the changes.

To check progress: cd ~/worktrees/.config/add-curl-permissions && claude
To clean up when done: worktree remove add-curl-permissions
```

# Benefits

- **True Isolation**: Separate Claude session, separate directory, no permission issues
- **Run From Anywhere**: No directory access permissions needed in main session
- **Parallel Work**: Continue your current work while updates happen
- **Clean State**: Worktree has isolated git state
- **Simple Cleanup**: One command to remove worktree

Arguments: $ARGUMENTS (description of what settings to update)
