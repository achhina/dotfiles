---
description: Document tricky solutions in CLAUDE.local.md for future sessions
argument-hint: [topic]
---

# Task

Document tricky problems and their solutions in `CLAUDE.local.md` so knowledge persists across sessions.

# Instructions

1. **Review recent conversation:**
   - Look for problems that required multiple attempts to solve
   - Identify CLI commands that failed initially
   - Note ordering requirements or prerequisites that had to be figured out
   - Find non-obvious solutions or workarounds

2. **Determine what to document:**
   - CLI commands that took 3+ attempts to get right
   - Specific ordering requirements (A must happen before B)
   - Prerequisites that weren't obvious
   - Workarounds for bugs or limitations
   - Configuration that deviated from defaults
   - Solutions that required domain knowledge

3. **Update CLAUDE.local.md:**
   - Read existing `CLAUDE.local.md` if it exists, otherwise create it
   - Add a new section with a clear heading
   - Document the problem and solution concisely
   - Include specific commands, file paths, and error messages if relevant
   - Use code blocks for commands and configuration

4. **Format:**
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

5. **Confirm:**
   - Show what was added to CLAUDE.local.md
   - Explain why this knowledge is worth preserving

# What NOT to Document

- Obvious or standard procedures
- One-off commands that won't be needed again
- Common knowledge or easily googleable information

# Example

If we just spent time figuring out that Claude Code can't read symlinks (but now it can), we might document:

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
