---
description: Remove obvious and redundant comments from uncommitted code changes
---

# Task

Launch the comment-remover agent to clean up obvious and redundant comments from uncommitted changes.

# Agent Invocation

Use the Task tool with `subagent_type="comment-remover"` to launch the comment removal specialist.

The agent will autonomously:
1. Identify uncommitted changes using git
2. Review files for obvious and redundant comments
3. Remove comments that don't add value
4. Preserve important contextual comments
5. Provide a summary of what was cleaned up

# When to Use

Use this command:
- Before committing code (as part of /finalize workflow)
- When cleaning up code after implementation
- To improve code clarity by removing noise

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

Arguments: $ARGUMENTS (optional: file paths to focus on)
