#!/usr/bin/env bash
# PreToolUse hook to track permission requests for timeout monitoring
# This hook logs permission requests; a separate daemon handles auto-deny

set -euo pipefail

# Read hook input
INPUT=$(cat)

# Extract tool name and check if permission was requested
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
REQUIRES_PERMISSION=$(echo "$INPUT" | jq -r '.requires_permission // false')

# If this tool requires permission, log it for the timeout daemon
if [[ "$REQUIRES_PERMISSION" == "true" ]]; then
    STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/claude/permission-timeouts"
    mkdir -p "$STATE_DIR"

    # Create a unique ID for this permission request
    REQUEST_ID=$(echo "$INPUT" | jq -r '.request_id // ""')
    if [[ -z "$REQUEST_ID" ]]; then
        # Generate ID from tool name + timestamp if not provided
        REQUEST_ID=$(echo "${TOOL_NAME}_$(date +%s%N)" | shasum -a 256 | cut -d' ' -f1)
    fi

    # Log the permission request with timestamp
    TIMESTAMP=$(date +%s)
    echo "$INPUT" | jq -c --arg id "$REQUEST_ID" --arg ts "$TIMESTAMP" \
        '{request_id: $id, timestamp: $ts, tool_name: .tool_name, tool_input: .tool_input}' \
        > "$STATE_DIR/$REQUEST_ID.pending"
fi

# Always allow the hook to proceed (don't block)
exit 0
