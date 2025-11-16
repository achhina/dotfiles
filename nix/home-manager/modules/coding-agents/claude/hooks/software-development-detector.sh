#!/usr/bin/env bash
# SessionStart hook to detect software development projects
# Loads general software engineering principles when in a git repository

set -euo pipefail

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

# Get the git repository root
git_root=$(git rev-parse --show-toplevel 2>/dev/null)

# Software development project detected - load general principles
software_principles_md="$HOME/.claude/SOFTWARE_PRINCIPLES.md"

if [[ -f "$software_principles_md" ]]; then
    echo "=== Software Development Project Detected ==="
    echo ""
    echo "Git repository: $git_root"
    echo "Loading software engineering principles..."
    echo ""
    echo "---"
    echo ""
    cat "$software_principles_md"
    echo ""
    echo "---"
    echo ""
fi

exit 0
