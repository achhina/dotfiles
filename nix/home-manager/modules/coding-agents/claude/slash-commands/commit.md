---
description: Create a well-formatted commit with smart message
mode: edit
---

# Task

Create a commit with a well-formatted message following best practices.

# Instructions

1. **Review changes:**
   - Run `git status` to see modified files
   - Run `git diff` to see staged and unstaged changes
   - Understand what was changed and why

2. **Stage changes:**
   - If changes aren't staged, stage relevant files with `git add`
   - Verify staged changes with `git diff --cached`

3. **Draft commit message:**
   - **Format:** `<Verb> <what> [optional details]`
   - **Length:** 60-120 characters for the summary line
   - **Style rules:**
     - Start with present-tense verb (Add, Fix, Update, Remove, Refactor, Implement)
     - Be concise and specific
     - No praise adjectives (e.g., avoid "great", "awesome", "better")
     - Single line (no body unless necessary)
     - End with a period
     - Focus on "what" and "why", not "how"

4. **Verify message quality:**
   - Is it clear what changed?
   - Is it clear why it changed?
   - Would someone reading the git log understand this?
   - Does it follow the format rules above?

5. **Create commit:**
   - Use `git commit -m "message"` with HEREDOC for proper formatting
   - Show the commit hash after successful commit

6. **Verify:**
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

# Notes

- This command pairs with `/todo` for a tight development loop
- Each task from `/todo` should result in one atomic commit
- If changes are complex, consider multiple smaller commits
- Never commit without understanding what changed
