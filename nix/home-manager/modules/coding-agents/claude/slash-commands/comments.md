---
description: Remove obvious and redundant comments from uncommitted code changes
---

# Task

Remove obvious and redundant comments from uncommitted code changes only. Do not modify committed code.

# Instructions

1. First, run `git status` and `git diff` to identify uncommitted changes
2. Review only the files with uncommitted changes for comments to remove
3. Remove the following types of comments:
   - Comments that simply restate what the code obviously does (e.g., `// Calculate elapsed time` above `elapsed = end - start`)
   - Comments describing edits like "added", "removed", "changed", "updated"
   - Commented-out code blocks
   - Redundant explanations that add no value beyond reading the code itself
   - Obvious variable or function explanations (e.g., `// User ID` above `userId`)

4. **DO NOT** remove:
   - TODO, FIXME, HACK, NOTE, or similar marker comments
   - Comments that explain "why" rather than "what"
   - Comments that provide important context not obvious from the code
   - Comments that would leave a scope completely empty (e.g., empty interface bodies)
   - Documentation comments (JSDoc, docstrings, etc.)
   - License headers or attribution comments

5. Make edits using the Edit tool
6. After all edits, show a summary of what was removed

# Style

Be aggressive in removing obvious comments but conservative with contextual ones. When in doubt, keep the comment.
