---
name: commit-message
description: Generate clear, conventional commit messages from git diffs. Use when writing commit messages or reviewing staged changes.
---

# Commit Message Generation

This skill generates clear, conventional commit messages from git diffs by analyzing staged changes and recent commit history.

## When to Use This Skill

Use this skill when:
- Writing a commit message for staged changes
- Reviewing what to commit
- Need a well-formatted conventional commit message
- Analyzing git diffs to understand changes

## How It Works

1. **Analyze staged changes** - Run `git diff --staged` to see what will be committed
2. **Review recent commits** - Run `git log -5 --oneline` to understand commit message style
3. **Generate message** - Create a concise, conventional commit message
4. **Return message** - Provide the message for use in commit command

## Message Format

Follow this strict format:

```
<type>: <subject>

[optional body]
```

### Type (required)
Choose the most specific type:
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation only
- **style**: Formatting, missing semicolons, etc.
- **refactor**: Code restructuring without behavior change
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **chore**: Build process, dependencies, tooling
- **ci**: CI/CD configuration
- **build**: Build system or dependencies

### Subject (required)
- Present tense (Add, Fix, Update, not Added, Fixed, Updated)
- No period at the end
- 50 characters or less
- Lowercase after the colon
- Describe what changed and why, not how

### Body (optional)
- Use only when the subject needs additional context
- Wrap at 72 characters
- Explain motivation and contrast with previous behavior

## Guidelines

**Subject Rules:**
- ✓ `feat: add user authentication with JWT`
- ✓ `fix: prevent race condition in data loader`
- ✓ `docs: update API endpoint documentation`
- ✗ `Added user authentication` (not conventional format)
- ✗ `fix: Fixed the bug` (redundant, past tense)
- ✗ `Update stuff` (too vague)

**Be Specific:**
- ✓ `refactor: extract validation logic to separate module`
- ✗ `refactor: improve code`

**Single Responsibility:**
- If changes span multiple types, prefer the most significant one
- If truly mixed, consider suggesting multiple commits

## Process

1. **Run git commands:**
   ```bash
   git diff --staged
   git log -5 --oneline
   ```

2. **Analyze the diff:**
   - What files changed?
   - What's the nature of changes (new feature, bug fix, refactor)?
   - Is there a clear single purpose?

3. **Check commit history:**
   - Do they use conventional commits?
   - Any special patterns or conventions?

4. **Generate message:**
   - Choose the appropriate type
   - Write a concise subject
   - Add body only if needed

5. **Return:**
   Provide the message as a code block ready to use

## Examples

**Example 1: Simple feature**
```
Staged: New login component
Message: feat: add JWT-based login component
```

**Example 2: Bug fix with context**
```
Staged: Fix in error handler
Message: fix: prevent null pointer in async error handler

Adds null check before accessing error.stack property to avoid
crashes when error object is malformed.
```

**Example 3: Refactoring**
```
Staged: Extract functions
Message: refactor: extract database queries to repository layer
```

**Example 4: Documentation**
```
Staged: README updates
Message: docs: add installation instructions for Windows
```

## Key Principles

1. **Atomic commits** - One logical change per commit
2. **Present tense** - Always use present tense verbs
3. **Be concise** - Subject line under 50 chars
4. **Be specific** - Avoid vague terms like "update", "fix stuff"
5. **Conventional format** - Always use type prefix
6. **No redundancy** - Don't repeat information from the diff
7. **Focus on why** - Explain motivation, not implementation details
