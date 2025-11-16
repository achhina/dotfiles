#!/usr/bin/env bash
# SessionStart hook to detect Python projects and load PYTHON.md context
# Triggers when in a git repository with pyproject.toml at the root

set -euo pipefail

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

# Get the git repository root
git_root=$(git rev-parse --show-toplevel 2>/dev/null)

# Check if pyproject.toml exists at the repository root
if [[ ! -f "$git_root/pyproject.toml" ]]; then
    exit 0
fi

# Python project detected - load PYTHON.md context
python_md="$HOME/.claude/PYTHON.md"

if [[ -f "$python_md" ]]; then
    echo "=== Python Project Detected ==="
    echo ""
    echo "Found pyproject.toml at repository root: $git_root"
    echo "Loading Python development context..."
    echo ""
    echo "---"
    echo ""
    cat "$python_md"
    exit 0
fi

# PYTHON.md not found
exit 0
