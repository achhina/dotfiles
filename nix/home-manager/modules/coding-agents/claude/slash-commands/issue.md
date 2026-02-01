---
description: Create a GitHub issue with template discovery
argument-hint: "[issue]"
---

# Task

Create a GitHub issue using the github skill.

# Instructions

Use the `github` skill to create an issue. The skill will:

1. Validate the environment (git repo, GitHub remote, gh CLI auth)
2. Discover issue templates (repo templates or fallback)
3. If multiple templates exist, ask you to choose (bug report, feature request, etc.)
4. Generate concise issue content based on context
5. Infer the title format based on discovered templates
6. Open the draft in your IDE (if connected) for review
7. Let you edit, regenerate, or submit
8. Submit via `gh issue create` when you approve

The skill enforces concise content:
- Descriptions: 2-3 sentences max
- Bullet points: Complete thoughts, not paragraphs
- Context: Only non-obvious information

# Usage

```
/issue "Login fails with valid credentials"
/issue "Add dark mode support"
/issue
```

The skill will infer the title format based on project or user-scoped templates. If you don't provide an issue description, the skill will derive one from context or ask you.
