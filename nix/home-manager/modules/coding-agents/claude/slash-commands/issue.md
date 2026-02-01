---
description: Create a GitHub issue with template discovery
argument-hint: "[issue]"
---

# Task

Create a GitHub issue using the github skill.

# Repository Environment

## Git Repository Status
- Remote: !`git remote -v 2>/dev/null || echo "Not in a git repository"`
- GitHub CLI: !`gh auth status 2>&1 || echo "Not authenticated"`

## Available Issue Templates

### Project templates
!`fd -t f -e md . .github 2>/dev/null | grep -E '(ISSUE_TEMPLATE\.md$|ISSUE_TEMPLATE/)' || echo "None found"`

### Fallback templates
@fallbackTemplates@

## Available Repository Labels
!`gh label list --limit 100 2>/dev/null || echo "No labels configured"`

# Instructions

Use the `github` skill to create an issue. The skill will:

1. If multiple templates exist, ask you to choose (bug report, feature request, etc.)
2. Generate concise issue content based on context
3. Infer the title format based on discovered templates
4. Suggest appropriate labels from the available repository labels
5. Open the draft in your IDE (if connected) for review
6. Let you edit, regenerate, or submit
7. Submit via `gh issue create` when you approve

Example submission:
```bash
gh issue create \
  --title "Issue title" \
  --body-file /tmp/issue-draft.md \
  --label "bug,needs-triage"
```

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
