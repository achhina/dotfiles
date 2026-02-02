---
name: github
description: Create GitHub issues and pull requests with template discovery, concise content generation, and interactive refinement
---

# GitHub Issue and PR Creation

This skill automates GitHub issue and pull request creation with template discovery, concise content generation, and interactive refinement.

## When to Use This Skill

Use this skill when:
- Creating a GitHub issue
- Creating a GitHub pull request
- You need standardized, concise GitHub content
- You want to review before submitting

## How It Works

1. **Context Gathering** - Analyze git state, commits, and changes
2. **Template Discovery** - Find repo templates or use fallbacks
3. **Content Generation** - Create concise, structured content
4. **Interactive Refinement** - Review, edit, regenerate until ready
5. **Submission** - Submit via gh CLI when approved

## Instructions

### Initial Setup

Spawn the `@githubAutomationAgent@` agent with these instructions:

You are the GitHub automation agent. Your job is to create concise, well-structured GitHub issues or pull requests with an interactive review workflow.

### Step 1: Validate Environment

Check prerequisites:

1. **Git repository:** Run `git status`. If not in a repo, error and exit.
2. **GitHub remote:** Run `git remote -v | grep github.com`. If not found, error and exit.
3. **gh CLI authentication:** Run `gh auth status`. If not authenticated, instruct user to run `gh auth login` and exit.

### Step 2: Handle Uncommitted Changes (PRs only)

For pull requests:

1. Run `git status`
2. If uncommitted changes exist, run `/commit` slash command to create a commit
3. Continue after commit is created

For issues, skip this step.

### Step 3: Gather Context

Collect information for content generation:

1. **Recent commits:** `git log --oneline -5`
2. **All changes:** `git diff main...HEAD` (or appropriate base branch)
3. **Current branch:** Extract from `git branch --show-current`
4. **Related issues:** Search commit messages for `#123` patterns

### Step 4: Discover Template

**For Pull Requests:**

Search in priority order:
1. `.github/pull_request_template.md`
2. `.github/PULL_REQUEST_TEMPLATE/*.md` (if multiple, list and ask user to choose)
3. `docs/pull_request_template.md`
4. Fallback: Use `templates/pull_request.md` from this skill directory

**For Issues:**

Search in priority order:
1. `.github/ISSUE_TEMPLATE/*.md` or `.github/ISSUE_TEMPLATE/*.yml`
2. `.github/issue_template.md`
3. `docs/issue_template.md`
4. Root directory `issue_template.md`

If multiple issue templates found:
- List available templates with descriptions
- Use AskUserQuestion to let user choose (bug report, feature request, etc.)

If no repo templates found:
- If user didn't specify type, use AskUserQuestion to ask: bug report or feature request?
- Use appropriate fallback from `templates/bug_report.md` or `templates/feature_request.md`

### Step 5: Generate Content

**CRITICAL: Verbosity Control**

You must be concise. Follow these strict rules:

- **Descriptions:** 2-3 sentences maximum
- **Bullet points:** One complete thought per bullet, not paragraphs
- **Test plans:** Specific steps only, no prose explanations
- **Context:** Only include what's non-obvious from code/commits
- **Skip sections:** If a section doesn't apply, remove it entirely

**Content Generation:**

1. Read the template (repo or fallback)
2. Fill in sections based on gathered context:
   - **Title:** Use provided title or derive from branch/commits
   - **Description:** Summarize what changed/what problem exists (2-3 sentences)
   - **Related Issues:** Extract from commits or branch name
   - **Type of Change:** Check appropriate boxes based on git diff
   - **Testing:** List specific verification steps
   - **Checklist:** Mark relevant items
3. Replace all bracketed placeholders with actual content
4. Write to temp file: `$TMPDIR/github-pr-$(date +%s).md` or `$TMPDIR/github-issue-$(date +%s).md`

### Step 6: Interactive Refinement Loop

1. **Present Summary:**
   Display concise summary in terminal:
   ```
   Generated PR draft: /tmp/github-pr-1234567890.md

   Title: [title]
   Type: [type]
   Related: [related issues]

   Sections:
   - Description ([N] lines)
   - Testing ([N] items)
   - Checklist ([N] items)
   ```

2. **Open in IDE (if available):**
   - Use IDE openFile tool if it exists to open the temp file in the connected IDE
   - If IDE tool is unavailable, display full content in terminal and show temp file path

3. **Ask for Next Action:**
   Use AskUserQuestion with these options:
   - **"Submit as-is"** - Submit the current content
   - **"I made edits"** - Re-read the temp file, show updated summary, return to this step
   - **"Regenerate with changes"** - Ask what to change, regenerate content, return to step 2
   - **"Cancel"** - Exit without submitting

4. **Loop** until user selects "Submit as-is" or "Cancel"

### Step 7: Submit

When user selects "Submit as-is":

**For Pull Requests:**
```bash
gh pr create --title "[title]" --body-file /tmp/github-pr-[timestamp].md
```

**For Issues:**
```bash
gh issue create --title "[title]" --body-file /tmp/github-issue-[timestamp].md
```

**Handle Submission:**

1. Run the gh command
2. If successful:
   - Display the issue/PR URL
   - Report success
3. If failed:
   - Display the error message
   - Keep temp file
   - Use AskUserQuestion: "Submission failed. Review error, edit if needed, and try again?"
   - If user wants to retry, return to step 6

### Error Handling

**No changes for PR:**
- If `git diff main...HEAD` shows no changes: "No changes detected. Create commits first."
- Exit gracefully

**Not in git repository:**
- "Not in a git repository. GitHub issues/PRs require a repository context."
- Exit gracefully

**Not on GitHub:**
- "This repository doesn't use GitHub. These commands only work with GitHub repositories."
- Exit gracefully

**gh not authenticated:**
- "GitHub CLI not authenticated. Run: gh auth login"
- Exit gracefully

## Templates Location

This skill includes fallback templates in the `templates/` subdirectory:
- `pull_request.md` - Standard PR template
- `bug_report.md` - Bug issue template
- `feature_request.md` - Feature request template

## Key Principles

1. **Conciseness First** - Fight verbosity at every step
2. **Template Respect** - Use repo templates when they exist
3. **Interactive Control** - User reviews before submission
4. **Context Awareness** - Use git history to fill in details
5. **Graceful Errors** - Handle all failure cases clearly

## Example Usage

**User runs:** `/pr "Add authentication"`

**Agent flow:**
1. Validates environment
2. Commits any uncommitted changes
3. Gathers git context
4. Discovers `.github/pull_request_template.md` (or fallback)
5. Generates concise PR content in `/tmp/github-pr-1234567890.md`
6. Opens in IDE (if available)
7. Asks: Submit / I made edits / Regenerate / Cancel
8. User edits and selects "I made edits"
9. Agent re-reads, shows summary, asks again
10. User selects "Submit as-is"
11. Agent runs `gh pr create --title "Add authentication" --body-file /tmp/...`
12. Displays PR URL
