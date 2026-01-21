---
description: Update Claude Code configuration in Home Manager
argument-hint: [setting description]
---

# Task

Launch a background agent to update Claude Code configuration, commit the changes, and apply with Home Manager.

# Instructions

Use the Task tool to spawn an async update-cc-settings agent:

```
Task tool parameters:
- subagent_type: "update-cc-settings"
- run_in_background: true
- prompt: "<detailed-prompt>"
```

The prompt should include:
- The specific configuration change requested
- Which file(s) in `nix/home-manager/modules/coding-agents/claude/` need updates

The agent will autonomously:
1. Parse the user's configuration change request
2. Locate and read the relevant configuration file(s)
3. Apply the requested changes using the Edit tool
4. Run `hm switch` to apply the configuration
5. Invoke the `/commit` skill to create a commit
6. Provide a summary of what was changed

## Inform User

Tell the user:
- That a background agent has been launched to handle the update
- The task_id for checking output with TaskOutput tool
- What configuration change is being applied

# Example

**User runs:** `/update-cc-settings Add permission for curl commands`

**You launch Task:**
```
subagent_type: "update-cc-settings"
run_in_background: true
prompt: "Update the Claude Code configuration in nix/home-manager/modules/coding-agents/claude/claude.nix to add 'Bash(curl:*)' to the permissions allow list. After making the change, run 'hm switch' to apply it, then invoke the /commit skill to create a commit."
```

**You inform user:**
"Background agent launched (task_id: abc123) to add curl command permissions to Claude Code configuration. The agent will update the config, apply with Home Manager, and create a commit. Use TaskOutput to check progress."

Arguments: $ARGUMENTS (description of what settings to update)
