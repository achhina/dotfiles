# claude-doctor

Diagnostic and audit tool for Claude Code installations.

## Overview

`claude-doctor` provides two main functions:

**Diagnostic Checks** - Comprehensive health checks across your Claude Code environment:
- Environment setup (Claude CLI, Node.js)
- Configuration files (settings.json, CLAUDE.md)
- Plugin system (marketplaces, cache, symlinks)
- MCP servers
- Permissions
- Performance metrics
- Hooks

**Tool Audit** - Analyze approved tool calls from conversation history:
- Extract unique tool usage patterns
- Filter by date range
- Group by tool name and key parameters
- Export as Rich table or JSON

## Commands

### Diagnostic Checks

Run all checks:

```bash
claude-doctor           # Defaults to 'check' subcommand
claude-doctor check     # Explicit subcommand
```

### Filter checks by pattern

```bash
# Only environment checks
claude-doctor --filter "environment.*"

# Only plugin checks
claude-doctor --filter "plugin.*"

# Config and environment
claude-doctor --filter "(config|environment).*"
```

### Auto-fix issues

```bash
# Preview fixes
claude-doctor --dry-run --fix

# Apply fixes
claude-doctor --fix
```

### JSON output

```bash
# For automation/monitoring
claude-doctor --format json > report.json
```

### Verbosity

```bash
# Show info logs
claude-doctor -v

# Show debug logs
claude-doctor -vvv
```

## Check Categories

### Environment (Critical)
- `environment.claude_installed`: Verify Claude Code CLI
- `environment.claude_version`: Check version
- `environment.node_version`: Verify Node.js

### Configuration (Critical/High)
- `config.settings_file`: Validate settings.json
- `config.settings_writable`: Check write permissions
- `config.memory_file`: Verify CLAUDE.md

### Plugins (Medium)
- `plugin.marketplace_dir`: Check marketplaces directory
- `plugin.cache_dir`: Verify cache accessibility
- `plugin.broken_symlinks`: Find broken links

## Tool Usage Audit

Analyze approved tool calls from conversation history to understand your workflow patterns.

### Basic Usage

```bash
# Audit all conversations
claude-doctor audit-tools

# Filter by date range (absolute)
claude-doctor audit-tools --start-date 2026-01-01
claude-doctor audit-tools --start-date 2026-01-01 --end-date 2026-01-31

# Filter by date range (relative - pandas-style)
claude-doctor audit-tools --start-date -7d           # Last 7 days
claude-doctor audit-tools --start-date -1w           # Last week
claude-doctor audit-tools --start-date -1m           # Last month
claude-doctor audit-tools --start-date -1w --end-date -1d  # Last week excluding today

# Relative date formats: -Nd (days), -Nw (weeks), -Nm (months), -Ny (years)

# Export as JSON
claude-doctor audit-tools --format json > audit.json
```

### What Gets Audited

- **Approved tools only**: Only tool calls that weren't denied by user
- **Unique grouping**: Grouped by tool name + key parameters
  - `Edit: /path/to/file.py` (unique per file)
  - `Bash: git status` (unique per command pattern)
  - `Task: subagent-type` (unique per subagent)
- **Statistics**: Count, session count, first/last seen timestamps

### Permission Suggestions

Generate permission patterns for your allow list based on approved tool calls:

```bash
# Suggest new permissions to add
claude-doctor audit-tools --suggest-permissions

# Suggest from specific time period
claude-doctor audit-tools --start-date 2026-01-01 --suggest-permissions

# Export suggestions as JSON
claude-doctor audit-tools --suggest-permissions --format json
```

This analyzes all approved tool calls and suggests permission patterns that aren't already in your allow list. Patterns follow the format used in `~/.config/nix/home-manager/modules/coding-agents/claude/claude.nix`:

- **Bash commands**: `Bash(command:*)` - e.g., `Bash(git:*)`, `Bash(python3:*)`
- **File operations**: `Tool(//path/to/dir/**)` - e.g., `Read(//Users/username/.config/**)`
- **Other tools**: Just the tool name - `Glob`, `WebFetch`, etc.

Use this to identify which permissions you frequently approve manually and should add to your configuration.

### Use Cases

```bash
# Find most used tools in last week
claude-doctor audit-tools --start-date 2026-01-17

# Analyze specific project
claude-doctor audit-tools --project /path/to/.claude/projects

# Generate workflow report for analysis
claude-doctor audit-tools --format json | jq '.tool_calls[] | select(.count > 10)'

# Find permissions to add based on last month's usage
claude-doctor audit-tools --start-date 2026-01-01 --suggest-permissions
```

## Exit Codes

- `0`: All checks passed (check command only)
- `1`: One or more checks failed (check command only)

## Examples

```bash
# Quick health check
claude-doctor

# Detailed plugin diagnostics
claude-doctor -vv --filter "plugin.*"

# Fix all issues automatically
claude-doctor --fix

# Generate monitoring report
claude-doctor --format json | jq '.failed'
```

## Adding New Checks

New checks are added by decorating a function:

```python
@check(
    name="category.check_name",
    category="category",
    severity=CheckSeverity.MEDIUM,
    depends_on=["prerequisite.check"],
    description="What this validates"
)
def check_something() -> CheckResult:
    # Validation logic
    return CheckResult(
        name="category.check_name",
        status=CheckStatus.PASS,
        message="Check passed",
        severity=CheckSeverity.MEDIUM
    )
```

## See Also

- Design: `docs/plans/2026-01-22-claude-doctor-design.md`
- Implementation: `docs/plans/2026-01-22-claude-doctor-implementation.md`
