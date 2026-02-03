# Autonomous Mode Hook

## Overview

The autonomous mode hook prevents permission prompts by blocking tools that would require user approval. This enables Claude to work autonomously on long-running tasks without getting stuck waiting for permission responses.

## How It Works

```
Normal Mode:
  Claude → Needs Permission → Prompt → User Responds → Continue

Autonomous Mode:
  Claude → Needs Permission → BLOCKED → Helpful Message → Try Alternative
```

Instead of waiting for user response, tools requiring permissions are immediately blocked with a message guiding Claude to use allowed alternatives.

## Usage

### Method 1: Wrapper Command (Recommended)

```bash
claude-autonomous [claude_args...]
```

Example:

```bash
claude-autonomous --prompt "Refactor the entire codebase"
```

### Method 2: Environment Variable

```bash
export CLAUDE_AUTONOMOUS_MODE=true
claude [args...]
```

### Method 3: One-liner

```bash
CLAUDE_AUTONOMOUS_MODE=true claude --prompt "your task here"
```

## When to Use

✅ **Good for:**

- Long-running tasks while you're away (meetings, lunch, etc.)
- Repetitive operations with well-known tool requirements
- Testing your permission configuration
- Batch processing multiple files
- Refactoring tasks using allowed tools

❌ **Not recommended for:**

- First-time tasks that might need new permissions
- Complex operations requiring user decisions
- Security-sensitive work requiring explicit approval
- Debugging unknown issues

## Configuration

### Customize Blocked Tools

Edit `prevent-permission-prompts.sh` to adjust which tools are blocked:

```bash
case "$TOOL_NAME" in
    "Edit"|"Write")
        # Add your allowed paths
        if [[ ! "$FILE_PATH" =~ ^${HOME}/.config ]] && \
           [[ ! "$FILE_PATH" =~ ^${HOME}/docs ]]; then
            PERMISSION_REQUIRED=true
        fi
        ;;

    "Bash")
        # Add patterns to block
        if [[ "$COMMAND" =~ ^sudo ]] || \
           [[ "$COMMAND" =~ dangerous_pattern ]]; then
            PERMISSION_REQUIRED=true
        fi
        ;;
esac
```

### Adjust Your Allow List

For better autonomous operation, add frequently-used tools to your allow list in `claude.nix`:

```nix
permissions = {
  allow = [
    "Read"
    "Edit(${config.xdg.configHome}/**)"  # Allow config edits
    "Write(/tmp/**)"                      # Allow temp writes
    "Bash(git *)"                         # Allow git operations
    # Add more as needed
  ];
};
```

## How Claude Adapts

When a tool is blocked, Claude sees:

```
🤖 **Autonomous Mode: Permission Required**

This tool requires permission that would pause execution.

**Alternative approaches:**
- Use allowed tools
- Modify the task to avoid permissions
- Break down into smaller steps

**Tool attempted:** Edit
**Details:** { file_path: "/etc/config" }
```

Claude will then:

1. Understand the limitation
2. Find an alternative approach
3. Use allowed tools instead
4. Continue making progress

## Examples

### Example 1: Codebase Refactoring

```bash
# Start autonomous refactoring
claude-autonomous --prompt "Refactor all TypeScript files to use async/await"

# Claude will:
# - Read files (allowed)
# - Edit files in allowed directories (allowed)
# - Skip files in blocked paths (with message)
# - Use alternative approaches for blocked operations
# - Continue working autonomously
```

### Example 2: Documentation Updates

```bash
claude-autonomous --prompt "Update all README files with current architecture"

# Claude will:
# - Search for README files
# - Edit allowed README locations
# - Skip system/protected locations
# - Generate documentation using allowed tools
```

### Example 3: Test Suite Run

```bash
CLAUDE_AUTONOMOUS_MODE=true claude --prompt "Run all tests and fix failures"

# Claude will:
# - Run tests using allowed bash commands
# - Edit test files in allowed paths
# - Skip operations requiring dangerous commands
# - Report what couldn't be done autonomously
```

## Troubleshooting

### Hook Not Working

1. **Check deployment:**

   ```bash
   ls -la ~/.claude/hooks/
   # Should show prevent-permission-prompts.sh
   ```

2. **Verify environment variable:**

   ```bash
   echo $CLAUDE_AUTONOMOUS_MODE
   # Should output: true
   ```

3. **Check hook execution:**
   - Hook should log blocked actions to stderr
   - Look for "Autonomous Mode: Permission Required" messages

### Too Restrictive

If the hook blocks too many operations:

1. **Expand allow list** in `claude.nix`
2. **Adjust hook logic** in `prevent-permission-prompts.sh`
3. **Use normal mode** for that specific task

### Not Restrictive Enough

If permission prompts still appear:

1. **Add patterns** to the hook's case statement
2. **Check tool names** being used (might not match patterns)
3. **Verify autonomous mode is enabled** (check env var)

## Integration with Existing Workflow

### In Scripts

```bash
#!/usr/bin/env bash
# Long-running automation script

export CLAUDE_AUTONOMOUS_MODE=true

# Start autonomous task
claude --prompt "Process all pending tasks" &

# Do other work
do_other_stuff

# Wait for Claude to finish
wait
```

### With Tmux

```bash
# Start in tmux session
tmux new-session -d -s claude-work \
  "claude-autonomous --prompt 'Refactor codebase'"

# Detach and come back later
tmux attach -t claude-work
```

### As a Service

```bash
# Create systemd timer or launchd job
# Run autonomous tasks on schedule
```

## Limitations

1. **Can't actually prevent permission prompts** - Only blocks tools before they trigger prompts
2. **Requires configuration** - You must define which tools need permissions
3. **May be overly restrictive** - Could block legitimate operations
4. **Not true timeout** - Blocks immediately rather than waiting then denying

## Future Improvements

When Claude Code adds native timeout support, this hook can be updated to:

- Actually wait for timeout before denying
- Integrate with permission system directly
- Provide better feedback to both Claude and user
- Track denied permissions for analysis

## See Also

- Feature request: [Auto-deny Permission Prompts After Timeout](../../../../../scratchpad/claude-timeout-feature-request.md)
- Claude Code documentation on hooks
- Permission system documentation
