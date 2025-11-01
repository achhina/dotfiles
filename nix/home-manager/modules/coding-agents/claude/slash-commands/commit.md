---
description: Create a well-formatted commit with smart message
---

# Task

Launch a specialized commit agent to review changes, remove obvious comments, verify code quality, and create a well-formatted commit.

# Instructions

Use the Task tool to launch a commit agent that will:

1. **Review uncommitted changes:**
   - Run `git status` and `git diff` to identify all changes
   - Understand what was changed and why

2. **Clean up obvious comments:**
   - Remove comments that simply restate what the code does
   - Remove edit history comments ("added", "removed", "changed")
   - Remove commented-out code blocks
   - Keep TODO/FIXME markers, "why" comments, and documentation

3. **Stage changes:**
   - Stage relevant files with `git add`
   - Verify staged changes with `git diff --cached`

4. **Draft commit message:**
   - **Format:** `<Verb> <what> [optional details]`
   - **Length:** 60-120 characters for the summary line
   - **Style rules:**
     - Start with present-tense verb (Add, Fix, Update, Remove, Refactor, Implement)
     - Be concise and specific
     - No praise adjectives (avoid "great", "awesome", "better")
     - Single line (no body unless necessary)
     - End with a period
     - Focus on "what" and "why", not "how"

5. **Verify message quality:**
   - Is it clear what changed?
   - Is it clear why it changed?
   - Would someone reading the git log understand this?
   - Does it follow the format rules above?

6. **Create commit:**
   - Use `git commit -m "message"` with HEREDOC for proper formatting
   - Show the commit hash after successful commit

7. **Verify:**
   - Run `git status` to confirm commit succeeded
   - Run `git log -1 --oneline` to show the commit

# Message Examples

**Good:**
- `Add user authentication with JWT tokens.`
- `Fix memory leak in data processing pipeline.`
- `Update API endpoint to support pagination.`
- `Remove deprecated configuration options.`
- `Refactor database queries for performance.`

**Bad:**
- `Fixed stuff` (too vague)
- `Made the code better` (praise, not specific)
- `Updates` (incomplete, no details)
- `WIP` (not descriptive)
- `asdf` (meaningless)

# Comment Removal Guidelines

**Remove:**
- Comments that restate code: `// Calculate elapsed time` above `elapsed = end - start`
- Edit history: "added", "removed", "changed", "updated"
- Commented-out code
- Obvious explanations: `// User ID` above `userId`

**Keep:**
- TODO, FIXME, HACK, NOTE markers
- "Why" explanations
- Important context not obvious from code
- Documentation comments (JSDoc, docstrings)
- License headers

# Notes

- The agent will work through changes systematically
- Comment removal happens before commit creation
- Each task from `/todo` should result in one atomic commit
- If changes are complex, consider multiple smaller commits
- Never commit without understanding what changed

# Agent Invocation

Use the Task tool with subagent_type="general-purpose" to execute this workflow autonomously.
