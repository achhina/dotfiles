---
description: Update Claude Code configuration in Home Manager
argument-hint: [setting description]
allowed-tools:
  - Bash(worktree:*)
  - Bash(cd:*)
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Bash(hm:*)
  - Bash(home-manager:*)
---

# Task

Launch the update-cc-settings background agent to update Claude Code configuration settings in Home Manager modules in an isolated worktree.

# Instructions

Use the Task tool with the following parameters:
- `subagent_type`: "update-cc-settings"
- `run_in_background`: true
- `prompt`: Pass the user's request about what settings to update

The slash command has pre-configured permissions in its frontmatter for:
- Creating and removing git worktrees
- Running home manager commands (hm switch)
- Git operations (status, diff, add, commit)
- Directory navigation

## Agent Workflow

The agent will:
1. Create an isolated worktree using `worktree create update-cc-settings-<timestamp>`
2. Change to the worktree directory
3. Parse the user's instructions and identify required changes
4. Locate and read the appropriate Home Manager configuration files
5. Validate and apply changes using the Edit tool
6. Run `hm switch` to apply the configuration
7. Verify changes with `git diff` and `git status`
8. Create a well-formatted commit
9. Return to original directory
10. Optionally remove the worktree with `worktree remove`

# Usage

Simply invoke the slash command with a description of what to update:

```
/update-cc-settings Add permission for curl commands
```

```
/update-cc-settings Increase bash timeout to 10 minutes
```

```
/update-cc-settings Enable the debugging-toolkit plugin
```

The agent will automatically:
1. Create an isolated worktree
2. Make the requested changes
3. Apply configuration with hm switch
4. Commit the changes
5. Clean up the worktree

# Notes

- This command runs asynchronously in the background
- Uses an isolated worktree so your main working directory is unaffected
- You can continue working while the agent updates settings
- The agent will commit changes automatically
- Worktree is cleaned up after the agent completes
- Check task output with TaskOutput tool to see results
- All file changes happen in `~/.config` (the dotfiles repository)

# Benefits of Worktree Approach

- **Isolation**: Changes happen in a separate directory, main workspace untouched
- **Safety**: Failed updates don't leave your working directory dirty
- **Parallel Work**: Continue working on other tasks while settings update
- **Clean Commits**: Dedicated branch for the configuration update

Arguments: $ARGUMENTS (description of what settings to update)
