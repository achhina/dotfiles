---
description: Remove obvious and redundant comments from uncommitted code changes
---

# Task

Launch the comment-remover agent to clean up obvious and redundant comments from uncommitted changes.

# Agent Invocation

Use the Task tool with `subagent_type="comment-remover"` to launch the comment removal specialist.

The agent will autonomously:
1. When file paths provided: Check for uncommitted changes via git diff
   - If diff exists: Process only the uncommitted changes
   - If no diff: Process the entire file (even if committed)
2. When no file paths provided: Process all uncommitted changes
3. Review files for obvious and redundant comments
4. Remove comments that don't add value
5. Preserve important contextual comments
6. Provide a summary of what was cleaned up

# When to Use

Use this command:
- Before committing code (as part of /finalize workflow)
- When cleaning up code after implementation
- To improve code clarity by removing noise
- On specific files (committed or uncommitted) by passing file paths

# What Gets Removed

The agent removes:
- Obvious code restatements
- Edit history comments ("Added", "Changed", etc.)
- Commented-out code blocks
- Redundant explanations
- Empty placeholder comments

# What Gets Preserved

The agent preserves:
- TODO, FIXME, HACK, NOTE markers
- "Why" explanations and rationale
- Important context and workarounds
- Documentation comments (JSDoc, docstrings)
- License headers and attribution

# Arguments

Pass file paths to focus on specific files:
- `/comments path/to/file.py` - Process this file (diff if exists, else entire file)
- `/comments file1.js file2.js` - Process multiple specific files
- `/comments` - Process all uncommitted changes

The agent intelligently chooses scope:
- **With file path + uncommitted changes**: Process only the diff
- **With file path + no uncommitted changes**: Process entire file
- **Without file path**: Process all uncommitted changes across repository
