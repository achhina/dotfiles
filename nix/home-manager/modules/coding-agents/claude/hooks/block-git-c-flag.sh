#!/usr/bin/env bash
# PreToolUse hook to block git -C, --git-dir, and --work-tree flags
# These flags appear before subcommands and break permission patterns

set -euo pipefail

# Read the hook input JSON from stdin
INPUT=$(cat)

# Extract the tool name and command
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only check Bash tool calls
if [[ "$TOOL_NAME" != "Bash" ]]; then
    exit 0
fi

# Check for git directory flags
if echo "$COMMAND" | grep -qE 'git\s+(-C|--git-dir|--work-tree)'; then
    cat >&2 <<'EOF'
🚫 **Git `-C` flag detected!**

You're attempting to use `git -C <path>` or similar directory flags (`--git-dir`, `--work-tree`).

**Why this is blocked:**
- Claude Code bash permissions are configured with git subcommand patterns like `Bash(git commit:*)`
- These patterns match commands starting with the subcommand (e.g., `git commit`)
- The `-C` flag appears BEFORE the subcommand, causing permission mismatches
- Example: `git -C /path commit` doesn't match `Bash(git commit:*)` but `git commit` does

**What to use instead:**
Since the working directory is already set to the repository root, use plain git commands:

**Good:**
```bash
git status
git add file.txt
git commit -m "message"
git push
```

**Bad:**
```bash
git -C /Users/achhina/.config status
git -C /Users/achhina/.config add file.txt
git --git-dir=/path/to/.git commit
```

**Exception:** If you genuinely need to operate on a different repository, change your working directory first with `cd`, then use normal git commands.
EOF
    exit 2
fi

exit 0
