#!/usr/bin/env bash
# Daemon that monitors pending permission requests and auto-denies after timeout
# Usage: permission-timeout-daemon.sh [timeout_seconds]

set -euo pipefail

# Configuration
TIMEOUT_SECONDS="${1:-300}"  # Default: 5 minutes
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/claude/permission-timeouts"
POLL_INTERVAL=10  # Check every 10 seconds

# Ensure state directory exists
mkdir -p "$STATE_DIR"

echo "Permission timeout daemon started (timeout: ${TIMEOUT_SECONDS}s, poll: ${POLL_INTERVAL}s)"
echo "Monitoring: $STATE_DIR"

# Cleanup function
cleanup() {
    echo "Daemon shutting down..."
    exit 0
}

trap cleanup SIGINT SIGTERM

# Main monitoring loop
while true; do
    CURRENT_TIME=$(date +%s)

    # Process each pending permission request
    shopt -s nullglob
    for pending_file in "$STATE_DIR"/*.pending; do

        # Read the request data
        REQUEST_DATA=$(cat "$pending_file")
        # shellcheck disable=SC2034  # Used in future denial logging
        REQUEST_ID=$(echo "$REQUEST_DATA" | jq -r '.request_id')
        TIMESTAMP=$(echo "$REQUEST_DATA" | jq -r '.timestamp')
        TOOL_NAME=$(echo "$REQUEST_DATA" | jq -r '.tool_name')

        # Calculate elapsed time
        ELAPSED=$((CURRENT_TIME - TIMESTAMP))

        if [[ $ELAPSED -ge $TIMEOUT_SECONDS ]]; then
            echo "⏱️  Permission timeout for $TOOL_NAME (waited ${ELAPSED}s)"

            # Send auto-deny response
            # Note: This is where we'd send the denial to Claude
            # In practice, this requires access to Claude's stdin/permission system
            # For now, we'll log it and move the file

            # Create denial record
            DENIAL_MSG="Permission auto-denied after ${ELAPSED}s timeout.

This tool isn't in your permission allow list. To make progress autonomously:
1. Try an alternative approach using allowed tools
2. Or, ask the user to add this tool to the allow list
3. Or, break down the task differently

Tool: $TOOL_NAME
Timed out: $(date -r "$TIMESTAMP" '+%Y-%m-%d %H:%M:%S')
Duration: ${ELAPSED}s"

            echo "$DENIAL_MSG" > "${pending_file%.pending}.denied"

            # TODO: Actually send the denial to Claude
            # This would require integration with Claude's permission system
            # Possible approaches:
            # 1. Send to Claude's stdin (requires finding the process)
            # 2. Use Claude's API/control socket
            # 3. Modify permission response files

            # Remove pending file
            rm "$pending_file"

            echo "  → Denied and logged to ${pending_file%.pending}.denied"
        fi
    done

    sleep "$POLL_INTERVAL"
done
