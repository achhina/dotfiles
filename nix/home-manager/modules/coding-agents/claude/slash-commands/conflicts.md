---
description: Systematically resolve merge conflicts
---

# Task

Resolve all merge conflicts in the current repository, ensuring proper understanding of both sides before making decisions.

# Instructions

1. **Identify conflicts:**
   - Run `git status` to find files with conflicts
   - List all conflicted files

2. **For each conflicted file:**
   - Read the entire file to understand context
   - Identify all conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
   - Understand what each side is trying to do:
     - Current branch (HEAD): What we have
     - Incoming branch: What we're merging in

3. **Resolve conflicts strategically:**
   - Determine the correct resolution based on:
     - Which change is more recent or correct
     - Whether both changes can be combined
     - Project context and intent
   - Remove conflict markers
   - Ensure the result is syntactically correct
   - Preserve functionality from both sides when possible

4. **Verify resolution:**
   - For each file, ensure:
     - No conflict markers remain (`grep -n "<<<<<<< \|======= \|>>>>>>>" <file>`)
     - Code is syntactically valid
     - Logic makes sense
   - Run tests if available

5. **Stage resolved files:**
   - `git add <file>` for each resolved file
   - Verify all conflicts are resolved: `git status`

6. **Complete the operation:**
   - If in a rebase: `git rebase --continue`
   - If in a merge: `git commit`
   - If conflicts remain, repeat from step 2

7. **Summary:**
   - Show what conflicts were resolved
   - Explain key decisions made
   - Confirm the operation completed successfully

# Resolution Strategy

- **Keep both:** When changes don't overlap logically
- **Keep ours (HEAD):** When our changes are more correct/recent
- **Keep theirs:** When incoming changes are more correct/recent
- **Custom merge:** When both have valuable parts that need combining

# Example Conflict

```javascript
<<<<<<< HEAD
function greet(name) {
  return `Hello, ${name}!`;
}
=======
function greet(name) {
  return `Hi there, ${name}!`;
}
>>>>>>> feature-branch
```

Resolution depends on context - which greeting is preferred?
