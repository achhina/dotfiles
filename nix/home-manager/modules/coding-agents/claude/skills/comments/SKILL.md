---
name: comments
description: Remove obvious and redundant comments from code
argument-hint: "[--scope changes|codebase] [@path ...]"
disable-model-invocation: true
allowed-tools: ["Read", "Edit", "Grep", "Glob", "Bash(git *)"]
model: haiku
---

# Remove Spurious Comments

Remove obvious and redundant comments from code with flexible scope and file targeting.

## Purpose

Clean up code by removing comments that don't add value, while preserving important contextual information. This improves code clarity by reducing noise.

## Arguments

**Scope** (what to analyze):

- `--scope changes` (default) - uncommitted changes only
- `--scope codebase` - entire codebase

**File Targeting** (which files):

- Use `@` prefix to target specific files or directories
- Multiple paths supported: `@src/ @tests/ @utils.py`
- No `@` paths = process all files in scope

## Examples

```bash
/comments                           # All uncommitted changes
/comments --scope codebase          # Entire codebase
/comments @file.py                  # Uncommitted changes in file.py only
/comments @src/ @tests/            # Uncommitted changes in src/ and tests/
/comments --scope codebase @file.py # Entire file.py (not just uncommitted)
```

## Agent Invocation

Use the Task tool with `subagent_type="@commentRemoverAgent@"`.

Pass the arguments: $ARGUMENTS

The agent must parse the arguments to extract:

- `--scope` flag: `changes` (default) or `codebase`
- File/directory paths: Any arguments prefixed with `@`
- If no paths specified: process all files in scope

The agent will:

1. Parse `$ARGUMENTS` to determine scope and file targeting
2. For `changes` scope: use git diff to identify modified files (or filter to specified @ paths)
3. For `codebase` scope: process all files (or filter to specified @ paths)
4. Review files for obvious and redundant comments
5. Remove comments that don't add value
6. Preserve important contextual comments
7. Provide a summary of changes

## When to Use

- Before committing code (as part of /finalize workflow)
- When cleaning up code after implementation
- To improve code clarity by removing noise
- On specific files, directories, or entire codebase

## What Gets Removed

- Obvious code restatements (e.g., `// Set x to 5` above `x = 5`)
- Edit history comments ("Added", "Changed", "Updated")
- Commented-out code blocks
- Redundant explanations that add no value
- Empty placeholder comments

## What Gets Preserved

- TODO, FIXME, HACK, NOTE markers
- "Why" explanations and rationale
- Important context and workarounds
- Documentation comments (JSDoc, docstrings)
- License headers and attribution

## Warning

When using `--scope codebase`, this modifies files throughout the entire codebase. Review changes carefully before committing.
