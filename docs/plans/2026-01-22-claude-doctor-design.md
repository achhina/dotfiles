# Claude Doctor Design

**Date:** 2026-01-22
**Author:** AI Assistant
**Status:** Design Complete

## Overview

`claude-doctor.py` is a comprehensive diagnostic tool for Claude Code installations. It provides health checks across the entire Claude Code stack - from environment setup through configuration, plugins, MCP servers, and performance.

## Goals

1. **Comprehensive Coverage**: Check all aspects of Claude Code health in a single run
2. **Actionable Results**: Provide clear fix suggestions or auto-fix capabilities
3. **Flexible Filtering**: Regex-based check selection for targeted diagnostics
4. **Multiple Output Formats**: Rich visual output for humans, JSON for automation
5. **Extensible Design**: Easy to add new checks over time

## Architecture

### Core Components

**Check Registry System**: Central registry where diagnostic checks self-register using a decorator pattern. Each check is a function that returns a `CheckResult`.

**Dependency Resolution**: Checks can declare dependencies on other checks. The system performs topological sorting to run checks in the correct order, skipping dependent checks when prerequisites fail.

**Fix System**: Checks can provide either shell commands or Python functions to fix issues. The `--fix` flag applies these repairs, with `--dry-run` showing what would happen.

**Output Formatters**: Pluggable formatters for Rich tables (interactive) and JSON (automation).

## Data Models

### CheckStatus
```python
class CheckStatus(str, Enum):
    PASS = "pass"    # Check passed
    WARN = "warn"    # Non-critical issue
    FAIL = "fail"    # Check failed
    SKIP = "skip"    # Skipped due to dependency
```

### CheckSeverity
```python
class CheckSeverity(str, Enum):
    CRITICAL = "critical"  # System won't work
    HIGH = "high"          # Major functionality broken
    MEDIUM = "medium"      # Feature degradation
    LOW = "low"            # Minor issues or optimization
```

### CheckResult
```python
class CheckResult(BaseModel):
    name: str                                    # Unique check identifier
    status: CheckStatus                          # Pass/warn/fail/skip
    message: str                                 # Human-readable message
    details: dict[str, Any]                      # Extra context
    fix_command: Optional[str]                   # Shell command to fix
    fix_function: Optional[Callable[[], bool]]   # Python function to fix
    severity: CheckSeverity                      # Impact level
```

### CheckMetadata
```python
class CheckMetadata(BaseModel):
    name: str                    # Must be unique
    category: str                # Grouping (environment, config, plugin, etc.)
    severity: CheckSeverity      # Default severity
    depends_on: list[str]        # Check names this depends on
    description: str             # What this check does
```

### DiagnosticReport
```python
class DiagnosticReport(BaseModel):
    timestamp: str               # ISO format
    checks_run: int
    passed: int
    warned: int
    failed: int
    skipped: int
    results: list[CheckResult]
```

## Check Registry

### Decorator Pattern
```python
@check(
    name="category.specific_check",
    category="category",
    severity=CheckSeverity.HIGH,
    depends_on=["prerequisite.check"],
    description="What this check validates"
)
def check_function() -> CheckResult:
    """Check implementation."""
    # Validation logic
    return CheckResult(...)
```

### Registry Operations
- `get_checks_by_filter(pattern)`: Returns checks matching regex, topologically sorted
- Automatic dependency resolution with cycle detection
- Skip cascade: If critical check fails, dependents are skipped

## Check Categories

### Environment (Critical)
- `claude.installed`: Verify `claude` command exists
- `claude.version`: Check version is recent (warn if >30 days old)
- `claude.npm_location`: Verify installed from `~/.local/share/npm`
- `node.version`: Ensure Node.js meets minimum requirements

### Configuration (Critical/High)
- `config.settings_file`: Verify `~/.claude/settings.json` exists and is valid JSON
- `config.settings_writable`: Check not stuck as symlink
- `config.settings_backup`: Verify Home Manager backup exists
- `config.home_manager_integration`: Validate deployment
- `config.memory_file`: Check `~/.claude/CLAUDE.md`
- `config.project_memory`: Check `.config/CLAUDE.md` in git repos

### Plugins (High/Medium)
- `plugin.marketplace_dir`: Verify marketplaces directory
- `plugin.cache_dir`: Check cache accessibility
- `plugin.known_marketplaces`: Validate JSON structure
- `plugin.neovim_marketplace`: Check symlink integrity
- `plugin.enabled_plugins`: Verify all enabled plugins exist
- `plugin.broken_symlinks`: Find and report broken links

### MCP Servers (Medium)
- `mcp.servers_configured`: Parse settings for MCP definitions
- `mcp.server_executables`: Verify commands exist
- `mcp.neovim_socket`: Test socket connectivity

### Permissions (Medium)
- `permissions.allow_list`: Validate pattern syntax
- `permissions.deny_conflicts`: Check for contradictions
- `permissions.directory_access`: Verify additional directories

### Performance (Low)
- `performance.conversation_count`: Warn if >1000 conversations
- `performance.plugin_cache_size`: Suggest cleanup if >1GB
- `performance.settings_size`: Warn if settings.json >100KB

### Hooks (Medium)
- `hooks.session_start`: Verify hook scripts exist and are executable
- `hooks.script_validity`: Basic syntax validation

## CLI Interface

### Command Structure
```bash
claude-doctor [OPTIONS]
```

### Options
- `--format, -f {rich|json}`: Output format (default: rich)
- `--filter, -F PATTERN`: Regex to filter checks (e.g., "plugin.*")
- `--fix`: Automatically attempt fixes
- `--dry-run, -n`: Preview fixes without applying
- `--verbose, -v`: Increase verbosity (repeat for more: -v, -vv, -vvv)
- `--log-level {debug|info|warning|error}`: Set logging level

### Examples
```bash
# Run all checks
claude-doctor

# Only plugin checks
claude-doctor --filter "plugin.*"

# Preview what would be fixed
claude-doctor --dry-run --fix

# Fix all issues automatically
claude-doctor --fix

# Maximum verbosity
claude-doctor -vvv

# JSON output for automation
claude-doctor --format json > report.json

# Check config and environment only
claude-doctor --filter "(config|environment).*"
```

## Fix System

### Fix Types

**Shell Command Fixes**: Simple repairs via shell commands
```python
fix_command="chmod u+w ~/.claude/settings.json"
```

**Programmatic Fixes**: Complex repairs via Python functions
```python
def fix_settings_symlink() -> bool:
    settings = Path.home() / ".claude" / "settings.json"
    if settings.is_symlink():
        target = settings.readlink()
        settings.unlink()
        shutil.copy(target, settings)
        return True
    return False

fix_function=fix_settings_symlink
```

### Fix Application Flow
1. Collect all failed/warned checks with fixes
2. If `--dry-run`, print what would be done and exit
3. Otherwise, apply fixes in order:
   - Execute fix_function or fix_command
   - Re-run the check to verify success
   - Update result status if fixed
4. Report fix outcomes

## Output Formatting

### Rich Format (Default)
- Summary header with counts
- Grouped tables by category
- Color-coded status indicators:
  - ✓ Green for PASS
  - ⚠ Yellow for WARN
  - ✗ Red for FAIL
  - ○ Dim for SKIP
- Severity highlighting (critical = bold red)
- Fix suggestions section at the end

### JSON Format
- Structured machine-readable output
- Excludes non-serializable fields (fix_function)
- Suitable for monitoring systems and automation
- Schema matches DiagnosticReport model

## Error Handling

### Check Execution
- Each check wrapped in try-except
- Exceptions converted to FAIL results
- Full stack traces logged at debug level
- Exception details included in result

### Fix Execution
- Fix failures don't stop other fixes
- Fix errors logged and reported
- Original check result preserved if fix fails
- User notified of each fix attempt outcome

## Implementation Details

### Dependencies
```python
# /// script
# dependencies = ["click", "structlog", "rich", "pydantic"]
# ///
```

Same uv script pattern as `worktree.py`.

### Shell Integration
Deployed via Home Manager:
```nix
home.file."bin/claude-doctor" = {
  source = ../files/scripts/claude-doctor.py;
  executable = true;
};
```

### Completion Support
Uses `AutoloadZshComplete` from `worktree.py` for zsh completion with `fpath` autoloading. Completes check names for `--filter` option.

## Future Extensions

The check registry design makes adding new checks straightforward:

1. **Git Integration**
   - `git.worktree_health`: Validate worktree structure
   - `git.hooks_installed`: Verify git hooks

2. **Performance Profiling**
   - `performance.startup_time`: Measure and report startup duration
   - `performance.plugin_load_times`: Profile individual plugins

3. **Network Checks**
   - `network.mcp_connectivity`: Test MCP server reachability
   - `network.api_access`: Verify Anthropic API connectivity

4. **Configuration Validation**
   - `config.slash_commands`: Validate custom commands
   - `config.skills_syntax`: Check skill file structure
   - `config.agents_config`: Verify agent definitions

5. **Security Audits**
   - `security.permissions_audit`: Analyze permission scope
   - `security.plugin_signatures`: Verify plugin authenticity

Each extension is a new decorated function. No core infrastructure changes required.

## Design Decisions

### Why Collect All Failures?
Running all checks provides a complete picture of system health. Users can see all issues at once rather than playing whack-a-mole, fixing one issue only to discover another.

### Why Regex Filtering?
More flexible than hardcoded categories. Users can filter arbitrarily:
- `"plugin.*"` - all plugin checks
- `"config\\.settings.*"` - only settings-related config checks
- `"(critical|high).*"` - all high-severity checks (requires name conventions)

### Why Both Fix Types?
Shell commands work for simple repairs (chmod, mkdir, rm). Python functions handle complex logic (parsing JSON, moving files conditionally, network operations). Having both keeps checks simple while supporting sophisticated fixes.

### Why Auto-Fix?
Diagnostic tools that can fix issues save time. Following Homebrew's pattern (`brew doctor`), we provide dry-run for safety. Users can preview fixes before applying them.

### Why JSON Output?
Enables integration with monitoring systems, CI/CD pipelines, and automated alerting. The same tool serves both interactive debugging and automated operations.

## Success Criteria

The design succeeds when:

1. **Comprehensive**: Covers all critical Claude Code components
2. **Actionable**: Every failure includes a fix suggestion or auto-fix
3. **Extensible**: New checks added without core changes
4. **Reliable**: Never crashes; converts errors to FAIL results
5. **Fast**: Completes full check suite in <5 seconds
6. **Clear**: Rich output immediately shows what's wrong
7. **Automatable**: JSON output suitable for scripting

## Next Steps

1. Create isolated worktree for implementation
2. Write detailed implementation plan
3. Implement core infrastructure (models, registry, CLI)
4. Implement initial check set (environment, config)
5. Add output formatters
6. Implement fix system
7. Add shell completion
8. Testing and refinement
9. Deploy via Home Manager
