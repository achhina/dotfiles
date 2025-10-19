---
description: Remove obvious and redundant comments from entire codebase
---

# Task

Remove obvious and redundant comments across the entire codebase. This is the project-wide version of `/comments`.

# Instructions

1. Search the codebase for files containing comments (use appropriate tools like Grep or Glob)
2. Review files systematically for comments to remove
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

# Warning

This command modifies files throughout the entire codebase. Review changes carefully before committing.
