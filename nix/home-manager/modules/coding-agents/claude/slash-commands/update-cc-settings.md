---
description: Update Claude Code configuration in Home Manager
argument-hint: [setting description]
---

# Task

Launch the update-cc-settings background agent to update Claude Code configuration settings in Home Manager modules.

# Instructions

Use the Task tool with the following parameters:
- `subagent_type`: "update-cc-settings"
- `run_in_background`: true
- `prompt`: Pass the user's request about what settings to update

The agent will:
1. Parse the user's instructions and identify the required changes
2. Locate and read the appropriate Home Manager configuration files
3. Validate and apply the changes using the Edit tool
4. Run `hm switch` to apply the configuration
5. Verify the changes with `git diff`
6. Create a well-formatted commit

# Examples

**Example 1: Add a permission**
Request: "Add permission for curl commands"
```
Use the Task tool with:
- subagent_type: "update-cc-settings"
- run_in_background: true
- prompt: "Add permission for curl commands to the Claude Code configuration"
```

**Example 2: Update timeout**
Request: "Increase bash timeout to 10 minutes"
```
Use the Task tool with:
- subagent_type: "update-cc-settings"
- run_in_background: true
- prompt: "Increase bash timeout to 10 minutes in the Claude Code configuration"
```

**Example 3: Enable a plugin**
Request: "Enable the debugging-toolkit plugin"
```
Use the Task tool with:
- subagent_type: "update-cc-settings"
- run_in_background: true
- prompt: "Enable the debugging-toolkit@claude-code-workflows plugin"
```

# Notes

- This command runs asynchronously in the background
- You can continue working while the agent updates settings
- The agent will commit changes automatically
- Check task output with TaskOutput tool to see results

Arguments: $ARGUMENTS (description of what settings to update)
