---
description: Implement one task from .llm/todo.md
---

# Task

Implement the next pending task from `.llm/todo.md`, following a structured workflow from reading to completion.

# Instructions

1. **Read the todo list:**
   - Read `.llm/todo.md` if it exists
   - If it doesn't exist, inform the user and suggest creating one
   - Look for the first task marked with `[ ]` (pending)

2. **Select task:**
   - Identify the next pending task
   - If no pending tasks exist, check for in-progress tasks marked `[>]`
   - If all tasks are complete `[x]`, congratulate and ask for next steps

3. **Mark task as in progress:**
   - Update the task marker from `[ ]` to `[>]`
   - Use the Edit tool to update `.llm/todo.md`

4. **Implement the task:**
   - Break down the task if complex
   - Make the necessary code changes
   - Follow best practices (tests, documentation, etc.)
   - Ensure changes are working

5. **Mark task as complete:**
   - Update the task marker from `[>]` to `[x]`
   - Use the Edit tool to update `.llm/todo.md`

6. **Commit the changes:**
   - Automatically invoke `/commit` to commit the completed task
   - Or ask the user if they want to commit now

# Todo Format

The `.llm/todo.md` file uses this format:

```markdown
# Todo

- [ ] Task that hasn't started
- [>] Task currently in progress
- [x] Completed task
```

# Example Workflow

Given `.llm/todo.md`:
```markdown
# Todo

- [ ] Add user authentication
- [ ] Create login page
- [ ] Add password reset
```

The `/todo` command will:
1. Mark "Add user authentication" as `[>]`
2. Implement the authentication system
3. Mark "Add user authentication" as `[x]`
4. Commit the changes
5. Ready for next `/todo` invocation

# Notes

- This command pairs perfectly with `/commit` for a tight development loop
- Use `/worktree` to create isolated todo lists for parallel work
- Tasks should be atomic and completable in one session
