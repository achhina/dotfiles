---
description: Create a well-formatted commit with smart message
---

# Task

Launch the commit agent to review changes, remove obvious comments, generate a conventional commit message, and create a well-formatted commit.

# Instructions

Use the Task tool with the following parameters:

- `subagent_type`: "@commitAgent@"
- `prompt`: "Create a commit for the current changes"

The commit agent will:

1. Review uncommitted changes with `git status` and `git diff`
2. Clean up obvious and redundant comments from changed files
3. Stage changes with `git add`
4. Use the commit-message skill to generate a conventional commit message
5. Verify message quality
6. Create the commit with `git commit`
7. Confirm success with `git status` and `git log`

## Commit Message Format

The commit-message skill will generate messages in conventional commit format:

```
<type>: <subject>

[optional body]
```

**Types:** feat, fix, docs, style, refactor, perf, test, chore, ci, build

**Examples:**

- `feat: add user authentication with JWT`
- `fix: prevent race condition in data loader`
- `docs: update API endpoint documentation`
- `refactor: extract validation logic to separate module`

## Comment Removal Guidelines

The agent removes redundant comments but keeps important ones:

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

## Notes

- The commit agent uses the commit-message skill for message generation
- Each commit should be atomic (one logical change)
- If changes are complex, consider multiple smaller commits
- The agent will not commit without understanding what changed
