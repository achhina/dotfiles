# claude-doctor

Diagnostic tool for Claude Code installations.

## Overview

`claude-doctor` performs comprehensive health checks across your Claude Code environment, including:

- Environment setup (Claude CLI, Node.js)
- Configuration files (settings.json, CLAUDE.md)
- Plugin system (marketplaces, cache, symlinks)
- MCP servers
- Permissions
- Performance metrics
- Hooks

## Usage

### Run all checks

```bash
claude-doctor
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

## Exit Codes

- `0`: All checks passed
- `1`: One or more checks failed

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
