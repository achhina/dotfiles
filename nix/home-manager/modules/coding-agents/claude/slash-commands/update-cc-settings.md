---
description: Update Claude Code configuration in Home Manager
argument-hint: [setting description]
allowed-tools:
  - Bash(worktree:*)
---

# Task

Create an isolated worktree and launch an async background agent to update Claude Code configuration.

# Instructions

Follow these steps:

## 1. Synthesize Worktree Name

Based on the user's request (`$ARGUMENTS`), create a short, descriptive worktree name:
- Lowercase, hyphens, max 30 chars
- Examples: "add-curl-permissions", "increase-bash-timeout", "enable-debugging-plugin"

## 2. Create Worktree

Use the `worktree` CLI to create the worktree:
```bash
worktree create <synthesized-name>
```

This creates the worktree at `~/worktrees/.config/<synthesized-name>/`

## 3. Launch Background Task Agent

Use the Task tool to spawn an async update-cc-settings agent:

```
Task tool parameters:
- subagent_type: "update-cc-settings"
- run_in_background: true
- prompt: "<detailed-prompt>"
```

The prompt should include:
- The worktree path: `~/worktrees/.config/<synthesized-name>`
- Instruction to cd into the worktree first
- The specific configuration change requested
- Which file(s) in `nix/home-manager/modules/coding-agents/claude/` need updates
- Instructions to run `hm switch` to apply changes
- Instructions to verify with `git diff` and `git status`
- Instructions to create a commit
- Instruction to return to original directory when done

## 4. Inform User

Tell the user:
- The worktree name and location
- That a background agent has been launched to handle the update
- How to check task output: Use TaskOutput tool with the task_id
- How to clean up when done: `worktree remove <name>`

# Example

**User runs:** `/update-cc-settings Add permission for curl commands`

**You synthesize:**
- Worktree name: `add-curl-permissions`

**You execute:**
```bash
worktree create add-curl-permissions
```

**Then launch Task:**
```
subagent_type: "update-cc-settings"
run_in_background: true
prompt: "Change to the worktree directory at ~/worktrees/.config/add-curl-permissions. Update the Claude Code configuration in nix/home-manager/modules/coding-agents/claude/claude.nix to add \"Bash(curl:*)\" to the allowedTools list. After making the change, run 'hm switch' to apply it, verify with 'git diff' and 'git status', and create a commit with an appropriate message. When done, return to the original directory."
```

Arguments: $ARGUMENTS (description of what settings to update)
