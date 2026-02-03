#!/usr/bin/env bash
# PreToolUse hook to prevent permission prompts for autonomous operation
# Instead of waiting for timeout, immediately block tools that would require permission
# and guide Claude to use allowed alternatives

set -euo pipefail

# Configuration
AUTONOMOUS_MODE="${CLAUDE_AUTONOMOUS_MODE:-false}"  # Set via env var to enable

# If not in autonomous mode, allow everything through
if [[ "$AUTONOMOUS_MODE" != "true" ]]; then
    exit 0
fi

# Read hook input
INPUT=$(cat)

# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')

# Define tools that typically require permissions
# (Customize based on your allow list)
PERMISSION_REQUIRED=false

# Check if this tool would require permission
case "$TOOL_NAME" in
    # File operations outside allowed paths
    "Edit"|"Write")
        FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
        # Check if path is outside allowed directories
        # TODO: Read actual allowed directories from config
        if [[ ! "$FILE_PATH" =~ ^${HOME}/.config ]] && \
           [[ ! "$FILE_PATH" =~ ^${HOME}/docs ]]; then
            PERMISSION_REQUIRED=true
        fi
        ;;

    # Bash commands not in allow list
    "Bash")
        COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty')

        # Check against common disallowed patterns
        if [[ "$COMMAND" =~ ^sudo ]] || \
           [[ "$COMMAND" =~ rm\ -rf ]] || \
           [[ "$COMMAND" =~ chmod\ 777 ]] || \
           [[ "$COMMAND" =~ curl.*\|.*bash ]]; then
            PERMISSION_REQUIRED=true
        fi
        ;;

    # Add other tools that might need permission
    "NotebookEdit"|"TaskStop")
        # These might require permission in some contexts
        PERMISSION_REQUIRED=false  # Adjust based on your setup
        ;;
esac

# If permission would be required, block with helpful message
if [[ "$PERMISSION_REQUIRED" == "true" ]]; then
    cat >&2 <<'EOF'
🤖 **Autonomous Mode: Permission Required**

This tool requires permission that would pause execution waiting for user response.

To maintain autonomous operation, this action has been blocked.

**Alternative approaches:**
- Use allowed tools (check your permission allow list)
- Modify the task to avoid requiring permissions
- Break down into smaller steps using allowed operations
- Ask the user to add this tool/path to the allow list

**Tool attempted:**
EOF
    echo "$TOOL_NAME" >&2
    echo "" >&2
    echo "**Details:**" >&2
    echo "$TOOL_INPUT" | jq -C '.' >&2 || echo "$TOOL_INPUT" >&2

    # Block the action
    exit 2
fi

# Tool doesn't require permission, allow it
exit 0
