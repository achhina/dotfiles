---
description: Create a GitHub issue with template discovery
argument-hint: "[title]"
---

# Task

Create a GitHub issue using the github skill.

# Instructions

Use the `github` skill to create an issue. The skill will:

1. Validate the environment (git repo, GitHub remote, gh CLI auth)
2. Discover issue templates (repo templates or fallback)
3. If multiple templates exist, ask you to choose (bug report, feature request, etc.)
4. Generate concise issue content based on context
5. Open the draft in your IDE (if connected) for review
6. Let you edit, regenerate, or submit
7. Submit via `gh issue create` when you approve

The skill enforces concise content:
- Descriptions: 2-3 sentences max
- Bullet points: Complete thoughts, not paragraphs
- Context: Only non-obvious information

# Usage

```
/issue "Bug: Login fails with valid credentials"
/issue "Feature: Add dark mode support"
/issue
```

If you don't provide a title, the skill will derive one from context or ask you.
