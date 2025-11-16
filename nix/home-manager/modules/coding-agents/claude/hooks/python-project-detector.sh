#!/usr/bin/env bash
# SessionStart hook to detect Python projects and load development context
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

# Python project detected - load context files
software_principles_md="$HOME/.claude/SOFTWARE_PRINCIPLES.md"
python_md="$HOME/.claude/PYTHON.md"

echo "=== Python Project Detected ==="
echo ""
echo "Found pyproject.toml at repository root: $git_root"
echo "Loading development context..."
echo ""
echo "---"
echo ""

# Load SOFTWARE_PRINCIPLES.md first (general principles)
if [[ -f "$software_principles_md" ]]; then
    cat "$software_principles_md"
    echo ""
    echo "---"
    echo ""
fi

# Load PYTHON.md (Python-specific practices)
if [[ -f "$python_md" ]]; then
    cat "$python_md"
fi

exit 0
