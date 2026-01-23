# Claude Doctor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a comprehensive diagnostic tool for Claude Code installations with auto-fix capabilities.

**Architecture:** Registry-based check system with decorator pattern, topological dependency resolution, dual output formats (Rich/JSON), and integrated fix system.

**Tech Stack:** Python 3.x, Click (CLI), structlog (logging), Rich (tables), Pydantic (models), uv (script runner)

---

## Task 1: Create Script Foundation and Data Models

**Files:**
- Create: `nix/home-manager/files/scripts/claude-doctor.py`

**Step 1: Create script file with shebang and dependencies**

```python
#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["click", "structlog", "rich", "pydantic"]
# ///

"""
Diagnostic tool for Claude Code installations.

Provides comprehensive health checks across environment, configuration,
plugins, MCP servers, permissions, performance, and hooks.
"""

import json
import logging
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime
from enum import Enum
from functools import wraps
from pathlib import Path
from typing import Any, Callable, Optional

import click
import structlog
from click.shell_completion import ZshComplete, add_completion_class
from pydantic import BaseModel, ConfigDict, Field
from rich.console import Console
from rich.table import Table


# Custom ZshComplete for autoload compatibility
@add_completion_class
class AutoloadZshComplete(ZshComplete):
    """ZshComplete subclass for zsh autoload compatibility."""

    name = "zsh"

    @property
    def func_name(self) -> str:
        """Generate function name without _completion suffix."""
        safe_name = re.sub(r"\W+", "", self.prog_name.replace("-", "_"), flags=re.ASCII)
        return f"_{safe_name}"


# Constants
DEFAULT_LOG_LEVEL = "warning"

# Global consoles
console = Console()
console_err = Console(file=sys.stderr, stderr=True)

# Configure logging
if any(key.endswith("_COMPLETE") for key in os.environ.keys()):
    log_level_int = logging.CRITICAL
else:
    log_level_int = getattr(logging, DEFAULT_LOG_LEVEL.upper())

structlog.configure(
    processors=[
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.dev.ConsoleRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(log_level_int),
    logger_factory=structlog.PrintLoggerFactory(file=sys.stderr),
)

logger = structlog.get_logger()
```

**Step 2: Add data models**

Add after the logger initialization:

```python
# Data Models

class CheckStatus(str, Enum):
    """Status of a diagnostic check."""
    PASS = "pass"
    WARN = "warn"
    FAIL = "fail"
    SKIP = "skip"


class CheckSeverity(str, Enum):
    """Severity level of a check."""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class CheckResult(BaseModel):
    """Result of a diagnostic check."""
    model_config = ConfigDict(arbitrary_types_allowed=True)

    name: str
    status: CheckStatus
    message: str
    details: dict[str, Any] = Field(default_factory=dict)
    fix_command: Optional[str] = None
    fix_function: Optional[Callable[[], bool]] = Field(default=None, exclude=True)
    severity: CheckSeverity = CheckSeverity.MEDIUM


class CheckMetadata(BaseModel):
    """Metadata for a diagnostic check."""
    name: str
    category: str
    severity: CheckSeverity
    depends_on: list[str] = Field(default_factory=list)
    description: str


class DiagnosticReport(BaseModel):
    """Complete diagnostic report."""
    timestamp: str
    checks_run: int
    passed: int
    warned: int
    failed: int
    skipped: int
    results: list[CheckResult]
```

**Step 3: Verify script can be imported**

Run: `python -c "import sys; sys.path.insert(0, 'nix/home-manager/files/scripts'); import claude_doctor"`

Expected: No errors (module loads successfully)

**Step 4: Commit**

```bash
git add nix/home-manager/files/scripts/claude-doctor.py
git commit -m "feat: add claude-doctor script foundation and data models

- Add uv script shebang and dependencies
- Implement CheckStatus, CheckSeverity enums
- Add CheckResult, CheckMetadata, DiagnosticReport models
- Configure structlog with completion mode detection
- Add AutoloadZshComplete for shell completion"
```

---

## Task 2: Implement Check Registry System

**Files:**
- Modify: `nix/home-manager/files/scripts/claude-doctor.py`

**Step 1: Add check registry**

Add after the data models:

```python
# Check Registry

_CHECK_REGISTRY: dict[str, tuple[CheckMetadata, Callable]] = {}


def check(
    name: str,
    category: str,
    severity: CheckSeverity = CheckSeverity.MEDIUM,
    depends_on: Optional[list[str]] = None,
    description: str = "",
) -> Callable:
    """Decorator to register a diagnostic check."""

    def decorator(func: Callable[[], CheckResult]) -> Callable:
        metadata = CheckMetadata(
            name=name,
            category=category,
            severity=severity,
            depends_on=depends_on or [],
            description=description or func.__doc__ or "",
        )
        _CHECK_REGISTRY[name] = (metadata, func)

        @wraps(func)
        def wrapper() -> CheckResult:
            return func()

        return wrapper

    return decorator


def get_checks_by_filter(pattern: Optional[str] = None) -> list[tuple[CheckMetadata, Callable]]:
    """Get checks matching regex pattern, in dependency order."""
    if pattern:
        regex = re.compile(pattern)
        filtered = {k: v for k, v in _CHECK_REGISTRY.items() if regex.search(k)}
    else:
        filtered = _CHECK_REGISTRY

    # Topological sort by dependencies
    sorted_checks = []
    resolved = set()

    def resolve(name: str):
        if name in resolved:
            return
        if name not in filtered:
            return

        metadata, func = filtered[name]
        for dep in metadata.depends_on:
            resolve(dep)

        sorted_checks.append((metadata, func))
        resolved.add(name)

    for name in filtered:
        resolve(name)

    return sorted_checks


def safe_check_wrapper(metadata: CheckMetadata, check_func: Callable) -> CheckResult:
    """Wrap check execution with error handling."""
    try:
        return check_func()
    except Exception as e:
        logger.exception("check_error", check=metadata.name)
        return CheckResult(
            name=metadata.name,
            status=CheckStatus.FAIL,
            message=f"Check raised exception: {type(e).__name__}: {e}",
            severity=metadata.severity,
            details={"exception": str(e), "type": type(e).__name__},
        )
```

**Step 2: Test registry with a dummy check**

Add at the end of the file:

```python
# Test check
@check(
    name="test.dummy",
    category="test",
    severity=CheckSeverity.LOW,
    description="Dummy check for testing registry",
)
def check_dummy() -> CheckResult:
    """Dummy check."""
    return CheckResult(
        name="test.dummy",
        status=CheckStatus.PASS,
        message="Registry working",
        severity=CheckSeverity.LOW,
    )


if __name__ == "__main__":
    # Test registry
    checks = get_checks_by_filter()
    print(f"Registered checks: {len(checks)}")
    for meta, func in checks:
        print(f"  - {meta.name}: {meta.description}")
```

**Step 3: Run test**

Run: `python nix/home-manager/files/scripts/claude-doctor.py`

Expected output:
```
Registered checks: 1
  - test.dummy: Dummy check for testing registry
```

**Step 4: Remove test code**

Remove the test check and `if __name__ == "__main__"` block added in step 2.

**Step 5: Commit**

```bash
git add nix/home-manager/files/scripts/claude-doctor.py
git commit -m "feat: implement check registry with dependency resolution

- Add @check decorator for self-registering checks
- Implement get_checks_by_filter with regex filtering
- Add topological sort for dependency ordering
- Implement safe_check_wrapper for exception handling"
```

---

## Task 3: Implement Environment Checks

**Files:**
- Modify: `nix/home-manager/files/scripts/claude-doctor.py`

**Step 1: Add environment checks**

Add before the final `if __name__ == "__main__"` (which we'll add later):

```python
# Environment Checks

@check(
    name="environment.claude_installed",
    category="environment",
    severity=CheckSeverity.CRITICAL,
    description="Verify Claude Code is installed",
)
def check_claude_installed() -> CheckResult:
    """Check if claude command exists in PATH."""
    try:
        result = subprocess.run(
            ["which", "claude"],
            capture_output=True,
            text=True,
            check=False,
        )

        if result.returncode == 0:
            claude_path = result.stdout.strip()
            return CheckResult(
                name="environment.claude_installed",
                status=CheckStatus.PASS,
                message=f"Claude Code found at {claude_path}",
                severity=CheckSeverity.CRITICAL,
                details={"path": claude_path},
            )
        else:
            return CheckResult(
                name="environment.claude_installed",
                status=CheckStatus.FAIL,
                message="Claude Code not found in PATH",
                severity=CheckSeverity.CRITICAL,
                fix_command="npm install -g --prefix ~/.local/share/npm @anthropic-ai/claude-code",
                details={"expected_path": "~/.local/share/npm/bin/claude"},
            )
    except Exception as e:
        return CheckResult(
            name="environment.claude_installed",
            status=CheckStatus.FAIL,
            message=f"Error checking Claude installation: {e}",
            severity=CheckSeverity.CRITICAL,
        )


@check(
    name="environment.claude_version",
    category="environment",
    severity=CheckSeverity.MEDIUM,
    depends_on=["environment.claude_installed"],
    description="Check Claude Code version",
)
def check_claude_version() -> CheckResult:
    """Check if Claude Code version is recent."""
    try:
        result = subprocess.run(
            ["claude", "--version"],
            capture_output=True,
            text=True,
            check=True,
        )

        version_output = result.stdout.strip()

        return CheckResult(
            name="environment.claude_version",
            status=CheckStatus.PASS,
            message=f"Claude Code version: {version_output}",
            severity=CheckSeverity.MEDIUM,
            details={"version": version_output},
        )
    except subprocess.CalledProcessError as e:
        return CheckResult(
            name="environment.claude_version",
            status=CheckStatus.FAIL,
            message=f"Could not determine Claude Code version: {e.stderr}",
            severity=CheckSeverity.MEDIUM,
        )


@check(
    name="environment.node_version",
    category="environment",
    severity=CheckSeverity.HIGH,
    description="Check Node.js version",
)
def check_node_version() -> CheckResult:
    """Ensure Node.js meets minimum requirements."""
    try:
        result = subprocess.run(
            ["node", "--version"],
            capture_output=True,
            text=True,
            check=True,
        )

        version = result.stdout.strip()

        return CheckResult(
            name="environment.node_version",
            status=CheckStatus.PASS,
            message=f"Node.js version: {version}",
            severity=CheckSeverity.HIGH,
            details={"version": version},
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return CheckResult(
            name="environment.node_version",
            status=CheckStatus.FAIL,
            message="Node.js not found",
            severity=CheckSeverity.HIGH,
            fix_command="Install Node.js via Nix or system package manager",
        )
```

**Step 2: Test environment checks**

Add temporary test code at the end:

```python
if __name__ == "__main__":
    checks = get_checks_by_filter("environment.*")
    for meta, func in checks:
        result = safe_check_wrapper(meta, func)
        print(f"{result.name}: {result.status.value} - {result.message}")
```

**Step 3: Run test**

Run: `python nix/home-manager/files/scripts/claude-doctor.py`

Expected: All three environment checks run and show status

**Step 4: Remove test code**

Remove the temporary `if __name__ == "__main__"` block.

**Step 5: Commit**

```bash
git add nix/home-manager/files/scripts/claude-doctor.py
git commit -m "feat: add environment diagnostic checks

- Add claude_installed check (critical)
- Add claude_version check (depends on installed)
- Add node_version check
- Include fix commands for failures"
```

---

## Task 4: Implement Configuration Checks

**Files:**
- Modify: `nix/home-manager/files/scripts/claude-doctor.py`

**Step 1: Add configuration checks**

Add after environment checks:

```python
# Configuration Checks

@check(
    name="config.settings_file",
    category="config",
    severity=CheckSeverity.CRITICAL,
    description="Verify settings.json exists and is valid JSON",
)
def check_settings_file() -> CheckResult:
    """Check if settings.json exists and is valid JSON."""
    settings_path = Path.home() / ".claude" / "settings.json"

    if not settings_path.exists():
        return CheckResult(
            name="config.settings_file",
            status=CheckStatus.FAIL,
            message="settings.json does not exist",
            severity=CheckSeverity.CRITICAL,
            details={"path": str(settings_path)},
        )

    try:
        with open(settings_path) as f:
            json.load(f)

        return CheckResult(
            name="config.settings_file",
            status=CheckStatus.PASS,
            message="settings.json is valid JSON",
            severity=CheckSeverity.CRITICAL,
            details={"path": str(settings_path)},
        )
    except json.JSONDecodeError as e:
        return CheckResult(
            name="config.settings_file",
            status=CheckStatus.FAIL,
            message=f"settings.json is not valid JSON: {e}",
            severity=CheckSeverity.CRITICAL,
            details={"path": str(settings_path), "error": str(e)},
        )


@check(
    name="config.settings_writable",
    category="config",
    severity=CheckSeverity.HIGH,
    depends_on=["config.settings_file"],
    description="Verify settings file is writable",
)
def check_settings_writable() -> CheckResult:
    """Check if settings.json is writable (not stuck as symlink)."""
    settings_path = Path.home() / ".claude" / "settings.json"

    if settings_path.is_symlink():
        return CheckResult(
            name="config.settings_writable",
            status=CheckStatus.FAIL,
            message="settings.json is a symlink (should be mutable file)",
            severity=CheckSeverity.HIGH,
            fix_command="cp -L ~/.claude/settings.json ~/.claude/settings.json.tmp && rm ~/.claude/settings.json && mv ~/.claude/settings.json.tmp ~/.claude/settings.json",
            details={"target": str(settings_path.readlink())},
        )

    if not os.access(settings_path, os.W_OK):
        return CheckResult(
            name="config.settings_writable",
            status=CheckStatus.FAIL,
            message="settings.json is not writable",
            severity=CheckSeverity.HIGH,
            fix_command="chmod u+w ~/.claude/settings.json",
        )

    return CheckResult(
        name="config.settings_writable",
        status=CheckStatus.PASS,
        message="settings.json is writable",
        severity=CheckSeverity.HIGH,
    )


@check(
    name="config.memory_file",
    category="config",
    severity=CheckSeverity.MEDIUM,
    description="Verify CLAUDE.md memory file exists",
)
def check_memory_file() -> CheckResult:
    """Check if CLAUDE.md exists."""
    memory_path = Path.home() / ".claude" / "CLAUDE.md"

    if not memory_path.exists():
        return CheckResult(
            name="config.memory_file",
            status=CheckStatus.WARN,
            message="CLAUDE.md not found (optional but recommended)",
            severity=CheckSeverity.MEDIUM,
            details={"path": str(memory_path)},
        )

    return CheckResult(
        name="config.memory_file",
        status=CheckStatus.PASS,
        message="CLAUDE.md found",
        severity=CheckSeverity.MEDIUM,
        details={"path": str(memory_path)},
    )
```

**Step 2: Test configuration checks**

Add temporary test:

```python
if __name__ == "__main__":
    checks = get_checks_by_filter("config.*")
    for meta, func in checks:
        result = safe_check_wrapper(meta, func)
        print(f"{result.name}: {result.status.value} - {result.message}")
```

**Step 3: Run test**

Run: `python nix/home-manager/files/scripts/claude-doctor.py`

Expected: Config checks run and show status

**Step 4: Remove test code**

**Step 5: Commit**

```bash
git add nix/home-manager/files/scripts/claude-doctor.py
git commit -m "feat: add configuration diagnostic checks

- Add settings_file check with JSON validation
- Add settings_writable check with symlink detection
- Add memory_file check
- Include fix commands for writable and symlink issues"
```

---

## Task 5: Implement Plugin Checks

**Files:**
- Modify: `nix/home-manager/files/scripts/claude-doctor.py`

**Step 1: Add plugin checks**

Add after configuration checks:

```python
# Plugin Checks

@check(
    name="plugin.marketplace_dir",
    category="plugin",
    severity=CheckSeverity.MEDIUM,
    description="Verify marketplaces directory exists",
)
def check_marketplace_dir() -> CheckResult:
    """Check if marketplaces directory exists."""
    marketplace_dir = Path.home() / ".claude" / "plugins" / "marketplaces"

    if not marketplace_dir.exists():
        return CheckResult(
            name="plugin.marketplace_dir",
            status=CheckStatus.WARN,
            message="Marketplaces directory does not exist",
            severity=CheckSeverity.MEDIUM,
            fix_command=f"mkdir -p {marketplace_dir}",
            details={"path": str(marketplace_dir)},
        )

    return CheckResult(
        name="plugin.marketplace_dir",
        status=CheckStatus.PASS,
        message="Marketplaces directory exists",
        severity=CheckSeverity.MEDIUM,
        details={"path": str(marketplace_dir)},
    )


@check(
    name="plugin.cache_dir",
    category="plugin",
    severity=CheckSeverity.MEDIUM,
    description="Verify cache directory exists and is accessible",
)
def check_cache_dir() -> CheckResult:
    """Check if plugin cache directory is accessible."""
    cache_dir = Path.home() / ".claude" / "plugins" / "cache"

    if not cache_dir.exists():
        return CheckResult(
            name="plugin.cache_dir",
            status=CheckStatus.WARN,
            message="Plugin cache directory does not exist",
            severity=CheckSeverity.MEDIUM,
            fix_command=f"mkdir -p {cache_dir}",
            details={"path": str(cache_dir)},
        )

    if not os.access(cache_dir, os.R_OK | os.W_OK):
        return CheckResult(
            name="plugin.cache_dir",
            status=CheckStatus.FAIL,
            message="Plugin cache directory is not accessible",
            severity=CheckSeverity.MEDIUM,
            fix_command=f"chmod u+rw {cache_dir}",
            details={"path": str(cache_dir)},
        )

    return CheckResult(
        name="plugin.cache_dir",
        status=CheckStatus.PASS,
        message="Plugin cache directory accessible",
        severity=CheckSeverity.MEDIUM,
        details={"path": str(cache_dir)},
    )


@check(
    name="plugin.broken_symlinks",
    category="plugin",
    severity=CheckSeverity.MEDIUM,
    description="Scan for broken symlinks in plugin directories",
)
def check_plugin_broken_symlinks() -> CheckResult:
    """Find broken symlinks in plugin directories."""
    plugin_dirs = [
        Path.home() / ".claude" / "plugins" / "marketplaces",
        Path.home() / ".claude" / "plugins" / "cache",
    ]

    broken = []
    for base_dir in plugin_dirs:
        if not base_dir.exists():
            continue

        for path in base_dir.rglob("*"):
            if path.is_symlink() and not path.exists():
                broken.append(str(path))

    if broken:
        return CheckResult(
            name="plugin.broken_symlinks",
            status=CheckStatus.WARN,
            message=f"Found {len(broken)} broken symlink(s)",
            severity=CheckSeverity.MEDIUM,
            details={"broken_links": broken},
            fix_command=f"rm {' '.join(broken)}" if len(broken) <= 5 else "# Too many broken links, remove manually",
        )

    return CheckResult(
        name="plugin.broken_symlinks",
        status=CheckStatus.PASS,
        message="No broken symlinks found",
        severity=CheckSeverity.MEDIUM,
    )
```

**Step 2: Test plugin checks**

Add temporary test:

```python
if __name__ == "__main__":
    checks = get_checks_by_filter("plugin.*")
    for meta, func in checks:
        result = safe_check_wrapper(meta, func)
        print(f"{result.name}: {result.status.value} - {result.message}")
```

**Step 3: Run test**

Run: `python nix/home-manager/files/scripts/claude-doctor.py`

Expected: Plugin checks run successfully

**Step 4: Remove test code**

**Step 5: Commit**

```bash
git add nix/home-manager/files/scripts/claude-doctor.py
git commit -m "feat: add plugin diagnostic checks

- Add marketplace_dir check
- Add cache_dir check with permission validation
- Add broken_symlinks scanner with fix suggestions"
```

---

## Task 6: Implement CLI and Output Formatters

**Files:**
- Modify: `nix/home-manager/files/scripts/claude-doctor.py`

**Step 1: Add output formatting functions**

Add before the check definitions:

```python
# Output Formatting

def format_rich(report: DiagnosticReport) -> None:
    """Format report as Rich table."""
    # Summary
    console.print(f"\n[bold]Claude Code Diagnostic Report[/bold]")
    console.print(f"Timestamp: {report.timestamp}")
    console.print(f"Checks run: {report.checks_run}")

    summary_parts = []
    if report.passed > 0:
        summary_parts.append(f"[green]{report.passed} passed[/green]")
    if report.warned > 0:
        summary_parts.append(f"[yellow]{report.warned} warnings[/yellow]")
    if report.failed > 0:
        summary_parts.append(f"[red]{report.failed} failed[/red]")
    if report.skipped > 0:
        summary_parts.append(f"[dim]{report.skipped} skipped[/dim]")

    console.print(f"Results: {', '.join(summary_parts)}\n")

    # Group by category
    by_category: dict[str, list[CheckResult]] = {}
    for result in report.results:
        category = result.name.split(".")[0]
        by_category.setdefault(category, []).append(result)

    # Table per category
    for category, results in by_category.items():
        table = Table(title=f"{category.capitalize()} Checks")
        table.add_column("Check", style="cyan")
        table.add_column("Status", style="bold")
        table.add_column("Message")

        for result in results:
            # Status with color
            if result.status == CheckStatus.PASS:
                status = "[green]✓ PASS[/green]"
            elif result.status == CheckStatus.WARN:
                status = "[yellow]⚠ WARN[/yellow]"
            elif result.status == CheckStatus.FAIL:
                status = "[red]✗ FAIL[/red]"
            else:
                status = "[dim]○ SKIP[/dim]"

            # Check name without category prefix
            check_name = result.name.split(".", 1)[1]
            if result.status in (CheckStatus.FAIL, CheckStatus.WARN):
                if result.severity == CheckSeverity.CRITICAL:
                    check_name = f"[red bold]{check_name}[/red bold]"
                elif result.severity == CheckSeverity.HIGH:
                    check_name = f"[red]{check_name}[/red]"

            table.add_row(check_name, status, result.message)

        console.print(table)
        console.print()

    # Show fix suggestions
    fixable = [
        r
        for r in report.results
        if r.status in (CheckStatus.FAIL, CheckStatus.WARN)
        and (r.fix_command or r.fix_function)
    ]
    if fixable:
        console.print("[bold yellow]Suggested Fixes:[/bold yellow]")
        for result in fixable:
            if result.fix_command:
                console.print(f"  • {result.name}: [cyan]{result.fix_command}[/cyan]")
        console.print(f"\nRun with [cyan]--fix[/cyan] to apply fixes automatically\n")


def format_json(report: DiagnosticReport) -> None:
    """Format report as JSON."""
    print(
        report.model_dump_json(
            indent=2, exclude={"results": {"__all__": {"fix_function"}}}
        )
    )
```

**Step 2: Add CLI command**

Add at the end of the file:

```python
# CLI

@click.command(context_settings={"help_option_names": ["-h", "--help"]})
@click.option(
    "--format",
    "-f",
    type=click.Choice(["rich", "json"], case_sensitive=False),
    default="rich",
    help="Output format",
)
@click.option(
    "--filter",
    "-F",
    type=str,
    help="Regex pattern to filter checks (e.g., 'plugin.*')",
)
@click.option(
    "--fix", is_flag=True, help="Automatically attempt to fix issues"
)
@click.option(
    "--dry-run",
    "-n",
    is_flag=True,
    help="Show what fixes would be applied without applying them",
)
@click.option(
    "--verbose",
    "-v",
    count=True,
    help="Increase verbosity (can be repeated: -v, -vv, -vvv)",
)
@click.option(
    "--log-level",
    type=click.Choice(["debug", "info", "warning", "error"], case_sensitive=False),
    default=DEFAULT_LOG_LEVEL,
    help="Set logging level",
)
def main(
    format: str,
    filter: Optional[str],
    fix: bool,
    dry_run: bool,
    verbose: int,
    log_level: str,
):
    """Diagnostic tool for Claude Code installations.

    Runs comprehensive health checks on your Claude Code environment,
    including installation, configuration, plugins, and performance.

    Examples:

        claude-doctor                          # Run all checks

        claude-doctor --filter "plugin.*"      # Only plugin checks

        claude-doctor --dry-run --fix          # Preview fixes

        claude-doctor --fix                    # Fix issues automatically

        claude-doctor -vvv                     # Maximum verbosity
    """
    # Configure log level
    if verbose:
        log_level = ["warning", "info", "debug", "debug"][min(verbose, 3)]

    if not any(key.endswith("_COMPLETE") for key in os.environ.keys()):
        level_int = getattr(logging, log_level.upper())
        structlog.configure(
            processors=[
                structlog.processors.add_log_level,
                structlog.processors.TimeStamper(fmt="iso"),
                structlog.dev.ConsoleRenderer(),
            ],
            wrapper_class=structlog.make_filtering_bound_logger(level_int),
            logger_factory=structlog.PrintLoggerFactory(file=sys.stderr),
        )

    # Get checks to run
    checks = get_checks_by_filter(filter)

    if not checks:
        console_err.print(f"[yellow]No checks match filter: {filter}[/yellow]")
        sys.exit(1)

    # Run checks
    results = []
    skipped = set()

    for metadata, check_func in checks:
        # Skip if dependency failed
        if any(dep in skipped for dep in metadata.depends_on):
            result = CheckResult(
                name=metadata.name,
                status=CheckStatus.SKIP,
                message="Skipped due to failed dependency",
                severity=metadata.severity,
            )
            skipped.add(metadata.name)
        else:
            logger.info(f"Running check: {metadata.name}")
            result = safe_check_wrapper(metadata, check_func)
            if (
                result.status == CheckStatus.FAIL
                and metadata.severity == CheckSeverity.CRITICAL
            ):
                skipped.add(metadata.name)

        results.append(result)

    # Apply fixes if requested
    if fix:
        results = apply_fixes(results, dry_run)

    # Generate report
    report = DiagnosticReport(
        timestamp=datetime.now().isoformat(),
        checks_run=len(results),
        passed=sum(1 for r in results if r.status == CheckStatus.PASS),
        warned=sum(1 for r in results if r.status == CheckStatus.WARN),
        failed=sum(1 for r in results if r.status == CheckStatus.FAIL),
        skipped=sum(1 for r in results if r.status == CheckStatus.SKIP),
        results=results,
    )

    # Output report
    if format == "json":
        format_json(report)
    else:
        format_rich(report)

    # Exit with error if any checks failed
    if report.failed > 0:
        sys.exit(1)


def apply_fixes(results: list[CheckResult], dry_run: bool) -> list[CheckResult]:
    """Apply fixes for failed checks."""
    fixed_results = []

    for result in results:
        if result.status in (CheckStatus.FAIL, CheckStatus.WARN):
            if result.fix_command:
                if dry_run:
                    console_err.print(f"[blue]Would run: {result.fix_command}[/blue]")
                else:
                    try:
                        console_err.print(f"[cyan]Fixing {result.name}...[/cyan]")
                        subprocess.run(
                            result.fix_command,
                            shell=True,
                            check=True,
                            capture_output=True,
                            text=True,
                        )
                        console_err.print(f"[green]✓ Fixed: {result.name}[/green]")
                        result.status = CheckStatus.PASS
                        result.message += " (automatically fixed)"
                    except subprocess.CalledProcessError as e:
                        console_err.print(f"[red]✗ Fix failed: {result.name}[/red]")
                        logger.error("fix_command_error", check=result.name, error=e.stderr)

        fixed_results.append(result)

    return fixed_results


if __name__ == "__main__":
    main()
```

**Step 3: Test CLI**

Run: `python nix/home-manager/files/scripts/claude-doctor.py --help`

Expected: Help text displays with all options

**Step 4: Test actual run**

Run: `python nix/home-manager/files/scripts/claude-doctor.py`

Expected: All checks run and rich table output displays

**Step 5: Commit**

```bash
git add nix/home-manager/files/scripts/claude-doctor.py
git commit -m "feat: add CLI interface and output formatters

- Implement main Click command with all options
- Add format_rich with grouped tables and colors
- Add format_json for machine-readable output
- Implement apply_fixes with dry-run support
- Add dependency cascade and skip logic"
```

---

## Task 7: Deploy Script via Home Manager

**Files:**
- Modify: `nix/home-manager/modules/shell.nix`

**Step 1: Add script deployment**

Find the section with `home.file."bin/worktree"` and add after it:

```nix
  home.file."bin/claude-doctor" = {
    source = ../files/scripts/claude-doctor.py;
    executable = true;
  };
```

**Step 2: Add completion generation**

Find the `home.activation.generateWorktreeCompletion` section and add after it:

```nix
  # Generate claude-doctor completion after activation
  home.activation.generateClaudeDoctorCompletion = lib.hm.dag.entryAfter [ "installPackages" ] ''
    COMPLETIONS_DIR="$XDG_DATA_HOME/zsh/site-functions"
    mkdir -p "$COMPLETIONS_DIR"
    if [ -x $HOME/bin/claude-doctor ]; then
      $VERBOSE_ECHO "Generating claude-doctor zsh completions..."
      export PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:$PATH"
      if _CLAUDE_DOCTOR_COMPLETE=zsh_source $HOME/bin/claude-doctor > "$COMPLETIONS_DIR/_claude_doctor"; then
        touch "$COMPLETIONS_DIR"
      else
        echo "Warning: Failed to generate claude-doctor completions (exit code: $?)" >&2
      fi
    fi
  '';
```

**Step 3: Apply Home Manager changes**

Run: `home-manager switch`

Expected: Build succeeds and script is deployed to ~/bin/

**Step 4: Verify deployment**

Run: `which claude-doctor`

Expected: `/Users/achhina/bin/claude-doctor`

**Step 5: Test deployed script**

Run: `claude-doctor --help`

Expected: Help text displays

**Step 6: Commit**

```bash
git add nix/home-manager/modules/shell.nix
git commit -m "feat: deploy claude-doctor via Home Manager

- Add bin/claude-doctor deployment
- Add zsh completion generation activation script
- Follow same pattern as worktree deployment"
```

---

## Task 8: Test and Verify

**Files:**
- None (testing only)

**Step 1: Run full diagnostic**

Run: `claude-doctor`

Expected: All checks run, rich output displays with colored tables

**Step 2: Test filtering**

Run: `claude-doctor --filter "environment.*"`

Expected: Only environment checks run

**Step 3: Test JSON output**

Run: `claude-doctor --format json | jq '.checks_run'`

Expected: Number of checks run displayed

**Step 4: Test dry-run fix**

Run: `claude-doctor --dry-run --fix`

Expected: Shows what would be fixed without applying changes

**Step 5: Test verbosity**

Run: `claude-doctor -vvv --filter "config.*"`

Expected: Debug logging shows detailed execution

**Step 6: Verify completion**

Run: `claude-doctor --f<TAB>`

Expected: Completion suggests `--format` and `--filter`

**Step 7: Document verification**

Create verification summary in commit message.

**Step 8: Commit verification notes**

```bash
git commit --allow-empty -m "test: verify claude-doctor functionality

Verified:
- All checks execute successfully
- Rich output formatting works
- JSON output is valid
- Filtering by regex works
- Dry-run mode previews fixes
- Verbosity levels control logging
- Shell completion works"
```

---

## Task 9: Update Documentation

**Files:**
- Create: `docs/tools/claude-doctor.md`

**Step 1: Create documentation**

```markdown
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
```

**Step 2: Commit documentation**

```bash
git add docs/tools/claude-doctor.md
git commit -m "docs: add claude-doctor user documentation

- Add usage examples and patterns
- Document check categories
- Explain filtering and output formats
- Include guide for adding new checks"
```

**Step 3: Update main AGENTS.md if needed**

Check if AGENTS.md needs a reference to the new tool.

Run: `grep -i "diagnostic\|doctor\|health" nix/home-manager/modules/coding-agents/claude/context/AGENTS.md`

**Step 4: Add reference if appropriate**

If diagnostics aren't mentioned, consider adding a note about claude-doctor in the troubleshooting or tools section.

---

## Final Verification

Run full diagnostic suite:

```bash
# All checks
claude-doctor

# Verbose with all categories
claude-doctor -vvv

# JSON output validation
claude-doctor --format json | jq '.results | map(.status) | group_by(.) | map({status: .[0], count: length})'
```

Expected: Complete diagnostic report with all check categories passing on a healthy system.

---
