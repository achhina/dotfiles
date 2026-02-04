#!/usr/bin/env bash
# Helpful permission denial hook
# Provides guidance when a tool would be auto-denied in dontAsk mode

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Extract fields from hook input
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
PERMISSION_MODE=$(echo "$INPUT" | jq -r '.permission_mode // "default"')

# Only intervene in dontAsk mode (auto-deny mode)
if [ "$PERMISSION_MODE" != "dontAsk" ]; then
  exit 0
fi

# Read the allow list from Claude Code settings
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
  exit 0
fi

# Check if tool would be allowed
# Extract permission patterns from settings and check if tool matches any allow pattern
ALLOWED=$(jq -r --arg tool "$TOOL_NAME" '
  .permissions.allow // [] |
  map(select(
    . == $tool or
    (startswith("Bash(") and $tool == "Bash") or
    (startswith("mcp__") and ($tool | startswith("mcp__"))) or
    (. == "Read" and $tool == "Read") or
    (. == "Write" and $tool == "Write") or
    (. == "Edit" and $tool == "Edit") or
    (. == "Glob" and $tool == "Glob") or
    (. == "Grep" and $tool == "Grep") or
    (. == "Task" and $tool == "Task") or
    (. == "Skill" and $tool == "Skill") or
    (. == "WebFetch" and $tool == "WebFetch") or
    (. == "WebSearch" and $tool == "WebSearch")
  )) | length > 0
' "$SETTINGS_FILE")

# If tool is allowed, let it proceed
if [ "$ALLOWED" = "true" ]; then
  exit 0
fi

# Tool would be denied - provide helpful guidance
# Extract relevant allowed tools from settings
ALLOWED_TOOLS=$(jq -r '
  .permissions.allow // [] |
  map(select(
    . == "Read" or
    . == "Write" or
    . == "Edit" or
    . == "Glob" or
    . == "Grep" or
    . == "Task" or
    . == "Skill" or
    . == "WebFetch" or
    . == "WebSearch" or
    (startswith("Bash(") and . != "Bash") or
    (startswith("mcp__"))
  )) |
  unique |
  sort |
  .[] | "  - " + .
' "$SETTINGS_FILE")

# Construct helpful message
HELPFUL_MESSAGE="The user has explicitly asked you to complete this task.

However, the tool '$TOOL_NAME' is not in the allow list and will be auto-denied due to dontAsk permission mode.

You should try to accomplish the task using one of the allowed tools instead:

$ALLOWED_TOOLS

Consider alternative approaches:
- If you need to read files, use the Read tool
- If you need to search for code, use Grep or Glob
- If you need to edit files, use Edit or Write
- If you need to delegate work, use Task with a subagent
- If you need to run allowed bash commands, check the Bash(...) patterns in the list above

Think creatively about how to accomplish the user's goal within these constraints."

# Return denial with helpful message
jq -n \
  --arg tool "$TOOL_NAME" \
  --arg message "$HELPFUL_MESSAGE" \
  '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $message
    }
  }'

exit 0
