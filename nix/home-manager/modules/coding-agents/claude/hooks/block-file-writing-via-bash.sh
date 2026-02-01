#!/usr/bin/env bash
# PreToolUse hook to block file writing via bash commands
# Blocks patterns like: cat <<EOF, echo >, printf >

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

# Check for file-writing patterns at command start or after && only
# Match: cat > file.txt (at start) or cd /tmp && cat > file.txt (after &&)
# Exclude: git commit -m "cat > file.txt" (cat in quoted string)
FILE_WRITING_PATTERN='(^|&&\s+)(cat|echo|printf)\s+[^>]*>\s*[a-zA-Z0-9_./-]+'
EXCLUDE_PATTERN='(^|&&\s+).*>\s*(&[12]|/dev/)'

if rg -q "$FILE_WRITING_PATTERN" <<< "$COMMAND" && \
   ! rg -q "$EXCLUDE_PATTERN" <<< "$COMMAND"; then
    cat >&2 <<'EOF'
🚫 **File writing via bash detected!**

You're attempting to write file content using bash commands (cat <<EOF, echo >, or printf >).

**Why this is blocked:**
- The Write and Edit tools are specifically designed for file operations
- They provide better error handling and safety guarantees
- They work with Claude Code's file tracking system
- They don't require shell escaping or quote management
- They're explicitly mentioned in the tool usage policy

**What to use instead:**
- **Write tool**: For creating new files or completely replacing file contents
- **Edit tool**: For modifying existing files with precise string replacements

**Example:**
Instead of:
  cat > file.txt << 'EOF'
  content here
  EOF

Use:
  Write tool with:
  - file_path: file.txt
  - content: content here

**Exception:** If you genuinely need bash for piping, redirection chains, or processing command output, consider whether the operation is truly a shell task or if it's file manipulation disguised as shell work.
EOF
    exit 2
fi

exit 0
