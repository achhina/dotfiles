---
description: Create git worktree for parallel development
argument-hint: [task-description]
---

# Task

Create a new git worktree for parallel development, enabling you to work on multiple tasks simultaneously in separate directories.

# Instructions

1. **Get task description:**
   - If `$ARGUMENTS` is provided, use it as the task description
   - Otherwise, ask the user for a brief task description

2. **Create worktree:**
   - Generate a branch name from the task description (lowercase, hyphens, no special chars)
   - Run `git worktree list` to see existing worktrees
   - Create worktree: `git worktree add -b <branch-name> ../<directory-name> <base-branch>`
   - Base branch is typically `main` or `master`

3. **Initialize task file:**
   - Create `.llm/todo.md` in the new worktree directory
   - Add a single task: `[ ] <task-description>`
   - This file will be used by the `/todo` command

4. **Show next steps:**
   - Print the path to the new worktree
   - Suggest: `cd ../<directory-name> && claude`
   - Explain that the new worktree has its own isolated file state

# Cleanup

To remove stale worktrees later:
```bash
git worktree list
git worktree remove <path>
```

# Example

Input: `/worktree Add user authentication`

Output:
- Creates worktree at `../add-user-authentication`
- Creates branch `add-user-authentication`
- Initializes `.llm/todo.md` with `[ ] Add user authentication`
- Shows: `cd ../add-user-authentication && claude`
