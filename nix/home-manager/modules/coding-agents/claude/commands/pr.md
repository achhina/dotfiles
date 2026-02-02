---
description: Create a GitHub pull request with template discovery
argument-hint: "[title]"
---

# Task

Create a GitHub pull request using the github skill.

# Instructions

Use the `github` skill to create a pull request. The skill will:

1. Validate the environment (git repo, GitHub remote, gh CLI auth)
2. Check for uncommitted changes and run `/commit` if needed
3. Discover PR templates (repo template or fallback)
4. Gather context from git commits and diff
5. Generate concise PR content
6. Open the draft in your IDE (if connected) for review
7. Let you edit, regenerate, or submit
8. Submit via `gh pr create` when you approve

The skill enforces concise content:

- Descriptions: 2-3 sentences max
- Bullet points: Complete thoughts, not paragraphs
- Test plans: Specific steps only
- Context: Only non-obvious information

# Usage

```
/pr "Add authentication system"
/pr "Fix login bug"
/pr
```

If you don't provide a title, the skill will derive one from your branch name or recent commits.
