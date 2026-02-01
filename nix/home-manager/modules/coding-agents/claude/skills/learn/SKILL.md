---
name: learn
description: Document tricky solutions in CLAUDE.local.md for future sessions. Use when a problem required multiple attempts, non-obvious solutions were found, or specific ordering/prerequisites were discovered.
argument-hint: "[topic]"
---

# Document Learnings

Document tricky problems and their solutions in `CLAUDE.local.md` so knowledge persists across sessions.

## Purpose

When you solve a problem that required multiple attempts, discover non-obvious solutions, or figure out specific ordering requirements, this knowledge should be preserved for future sessions. This skill captures those learnings in a structured format.

## When to Use

Claude should invoke this skill when:
- A problem required 3+ attempts to solve
- A CLI command failed initially and needed debugging
- Ordering requirements or prerequisites were discovered through trial and error
- Non-obvious solutions or workarounds were found
- Configuration deviated from defaults in surprising ways
- Solutions required domain knowledge not easily googleable

## Instructions

### 1. Review Recent Conversation

Look for problems that exhibited these patterns:
- Multiple attempts to get a command right
- Specific ordering requirements (A must happen before B)
- Prerequisites that weren't obvious
- Workarounds for bugs or limitations
- Configuration that deviated from defaults
- Solutions that required domain knowledge

### 2. Determine What to Document

Ask yourself:
- Will this problem likely occur again?
- Is the solution non-obvious?
- Did this waste significant time to figure out?
- Does this contradict common assumptions?

**Do NOT document:**
- Obvious or standard procedures
- One-off commands that won't be needed again
- Common knowledge or easily googleable information
- Temporary workarounds for bugs that will be fixed

### 3. Update CLAUDE.local.md

Read existing `CLAUDE.local.md` if it exists, otherwise create it at `${XDG_CONFIG_HOME:-$HOME/.config}/CLAUDE.local.md`.

Add a new section with this format:

```markdown
## [Topic/Problem]

[Brief description of the problem or requirement]

**Solution:**
[Explanation of what works]

**Key details:**
- [Important detail 1]
- [Important detail 2]

**Example:**
\`\`\`bash
[working command or code]
\`\`\`
```

### 4. Confirm

Show what was added to CLAUDE.local.md and explain why this knowledge is worth preserving.

## Example

If we spent time discovering that Claude Code can now read symlinks:

```markdown
## Claude Code and Symlinks

Previously, Claude Code couldn't read symlinks, requiring activation scripts
to copy files instead of using Home Manager's built-in symlinking.

**As of 2025:** Claude Code CAN read symlinks. The workaround is no longer needed.

**Working approach:**
\`\`\`nix
programs.claude-code.commandsDir = ./commands;
\`\`\`

This properly symlinks command files to `~/.claude/commands/`.
```

## Notes

- Keep entries concise but complete
- Include version information when relevant (e.g., "As of 2025")
- Use code blocks for commands and configuration
- Preserve existing structure when updating the file
