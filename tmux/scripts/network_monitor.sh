#!/bin/bash

# Network monitoring script for tmux status line
# Uses system tools to show real-time network usage

# Get primary network interface (usually en0 on macOS)
# shellcheck disable=SC2034
INTERFACE=$(route get default 2>/dev/null | grep interface | awk '{print $2}' || echo "en0")

# Use nettop for real-time network stats (macOS)
if command -v nettop >/dev/null 2>&1; then
    # nettop shows real-time rates
    nettop -P -l 1 -k time 2>/dev/null | awk '/Total/ {
        # Convert bytes to appropriate units
        down = $3; up = $6
        if (down >= 1048576) { down = sprintf("%.1fM", down/1048576) }
        else if (down >= 1024) { down = sprintf("%.1fK", down/1024) }
        else { down = sprintf("%.0f", down) }

        if (up >= 1048576) { up = sprintf("%.1fM", up/1048576) }
        else if (up >= 1024) { up = sprintf("%.1fK", up/1024) }
        else { up = sprintf("%.0f", up) }

        printf "↓%s ↑%s", down, up
    }'
else
    # Fallback for other systems
    echo "↓--- ↑---"
fi
