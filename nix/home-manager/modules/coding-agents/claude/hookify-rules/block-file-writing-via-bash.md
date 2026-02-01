---
name: block-file-writing-via-bash
enabled: true
event: bash
pattern: (cat\s*<<|echo\s+.*>|printf\s+.*>)
action: block
---

🚫 **File writing via bash detected!**

You're attempting to write file content using bash commands (`cat <<EOF`, `echo >`, or `printf >`).

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
```bash
cat > file.txt << 'EOF'
content here
EOF
```

Use:
```
Write tool with:
- file_path: file.txt
- content: content here
```

**Exception:** If you genuinely need bash for piping, redirection chains, or processing command output, consider whether the operation is truly a shell task or if it's file manipulation disguised as shell work.
