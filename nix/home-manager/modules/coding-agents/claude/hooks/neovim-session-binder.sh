#!/usr/bin/env bash
# SessionStart hook to bind Claude session to Neovim persistence session.
# Captures Claude's session ID and writes it to Neovim's session directory.

set -euo pipefail

# Read hook input from stdin (limit size to prevent memory exhaustion)
input=$(head -c 10000)

# Extract session ID from hook input
session_id=$(echo "$input" | jq -r '.session_id // empty')

# Only proceed if launched from Neovim (indicated by CLAUDE_FROM_NEOVIM env var)
if [[ -z "${CLAUDE_FROM_NEOVIM:-}" ]]; then
    exit 0
fi

# Validate session ID format (alphanumeric, hyphens, underscores only)
if [[ ! "$session_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "ERROR: Invalid session_id format: $session_id" >&2
    exit 1
fi

# Get current working directory
cwd=$(pwd) || {
    echo "ERROR: Failed to get current directory" >&2
    exit 1
}

# Get Neovim session directory
nvim_sessions_dir="${HOME}/.local/state/nvim/sessions"

# Ensure session directory exists
if ! mkdir -p "$nvim_sessions_dir"; then
    echo "ERROR: Failed to create session directory: $nvim_sessions_dir" >&2
    exit 1
fi

# Compute session file name matching persistence.nvim's naming convention.
# Format: %encoded%path or %encoded%path%%branch for git repos.
cwd_encoded="${cwd//\//%}"

# Validate encoding succeeded
if [[ -z "$cwd_encoded" ]]; then
    echo "ERROR: Failed to encode cwd: $cwd" >&2
    exit 1
fi

# Check if we're in a git repository and get branch name.
# Per AGENTS.md Section 7: Use plain git commands, not git -C.
branch=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
fi

# Construct session file path
if [[ -n "$branch" ]]; then
    # Include branch in session file name
    session_file="${nvim_sessions_dir}/.claude-session-${cwd_encoded}%%${branch}"
else
    session_file="${nvim_sessions_dir}/.claude-session-${cwd_encoded}"
fi

# Write session ID to file using atomic operation.
# Use temporary file + move to prevent partial reads.
temp_file="${session_file}.tmp.$$"

if ! echo "$session_id" > "$temp_file" 2>&1; then
    echo "ERROR: Failed to write Claude session ID to $temp_file" >&2
    rm -f "$temp_file"
    exit 1
fi

# Verify write succeeded
if [[ ! -s "$temp_file" ]]; then
    echo "ERROR: Session file created but is empty: $temp_file" >&2
    rm -f "$temp_file"
    exit 1
fi

# Atomic move to final location
if ! mv "$temp_file" "$session_file" 2>&1; then
    echo "ERROR: Failed to move session file to final location: $session_file" >&2
    rm -f "$temp_file"
    exit 1
fi

# Set restrictive permissions (user read/write only)
chmod 600 "$session_file"

exit 0
