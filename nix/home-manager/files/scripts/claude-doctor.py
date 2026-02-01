#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["click", "structlog", "rich", "pydantic", "claude-code-transcripts", "python-dateutil"]
# ///

from __future__ import annotations

import json
import logging
import os
import re
import shlex
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
from dateutil.relativedelta import relativedelta
from pydantic import BaseModel, ConfigDict, Field
from rich.console import Console
from rich.table import Table

"""
Diagnostic tool for Claude Code installations.

Provides comprehensive health checks across environment, configuration,
plugins, MCP servers, permissions, performance, and hooks.
"""


@add_completion_class
class AutoloadZshComplete(ZshComplete):
    """ZshComplete subclass for zsh autoload compatibility."""

    name = "zsh"

    @property
    def func_name(self) -> str:
        safe_name = re.sub(r"\W+", "", self.prog_name.replace("-", "_"), flags=re.ASCII)
        return f"_{safe_name}"


DEFAULT_LOG_LEVEL = "warning"

console = Console()
console_err = Console(file=sys.stderr, stderr=True)
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


def format_rich(report: DiagnosticReport) -> None:
    console.print("\n[bold]Claude Code Diagnostic Report[/bold]")
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

    by_category: dict[str, list[CheckResult]] = {}
    for result in report.results:
        parts = result.name.split(".", 1)
        category = parts[0] if parts else "unknown"
        by_category.setdefault(category, []).append(result)
    for category, results in by_category.items():
        table = Table(title=f"{category.capitalize()} Checks")
        table.add_column("Check", style="cyan")
        table.add_column("Status", style="bold")
        table.add_column("Message")

        for result in results:
            if result.status == CheckStatus.PASS:
                status = "[green]✓ PASS[/green]"
            elif result.status == CheckStatus.WARN:
                status = "[yellow]⚠ WARN[/yellow]"
            elif result.status == CheckStatus.FAIL:
                status = "[red]✗ FAIL[/red]"
            else:
                status = "[dim]○ SKIP[/dim]"

            parts = result.name.split(".", 1)
            check_name = parts[1] if len(parts) > 1 else result.name

            if ":" in check_name:
                main_name, sub_name = check_name.split(":", 1)
                check_name = f"  ↳ {sub_name}"
            message = result.message
            if result.status in (CheckStatus.FAIL, CheckStatus.WARN):
                if (
                    result.severity == CheckSeverity.CRITICAL
                    or result.severity == CheckSeverity.HIGH
                ):
                    message = f"[red]{message}[/red]"
                elif result.severity == CheckSeverity.MEDIUM:
                    message = f"[yellow]{message}[/yellow]"

            table.add_row(check_name, status, message)

        console.print(table)
        console.print()

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
        console.print("\nRun with [cyan]--fix[/cyan] to apply fixes automatically\n")


def format_json(report: DiagnosticReport) -> None:
    print(
        report.model_dump_json(
            indent=2, exclude={"results": {"__all__": {"fix_function"}}}
        )
    )


CLAUDE_HOME = Path.home() / ".claude"
PLUGIN_MARKETPLACE_DIR = CLAUDE_HOME / "plugins" / "marketplaces"
PLUGIN_CACHE_DIR = CLAUDE_HOME / "plugins" / "cache"


class CheckStatus(str, Enum):
    PASS = "pass"
    WARN = "warn"
    FAIL = "fail"
    SKIP = "skip"


class CheckSeverity(str, Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class CheckResult(BaseModel):
    model_config = ConfigDict(arbitrary_types_allowed=True)

    name: str
    status: CheckStatus
    message: str
    details: dict[str, Any] = Field(default_factory=dict)
    fix_command: Optional[str] = None
    fix_function: Optional[Callable[[], bool]] = Field(default=None, exclude=True)
    severity: CheckSeverity = CheckSeverity.MEDIUM


class CheckMetadata(BaseModel):
    name: str
    category: str
    severity: CheckSeverity
    depends_on: list[str] = Field(default_factory=list)
    description: str


class DiagnosticReport(BaseModel):
    timestamp: str
    checks_run: int
    passed: int
    warned: int
    failed: int
    skipped: int
    results: list[CheckResult]


_CHECK_REGISTRY: dict[str, tuple[CheckMetadata, Callable]] = {}


def check(
    name: str,
    category: str,
    severity: CheckSeverity = CheckSeverity.MEDIUM,
    depends_on: Optional[list[str]] = None,
    description: str = "",
) -> Callable:
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


def get_checks_by_filter(
    pattern: Optional[str] = None,
) -> list[tuple[CheckMetadata, Callable]]:
    """Get checks matching regex pattern, in dependency order.

    Args:
        pattern: Optional regex pattern to filter check names

    Returns:
        List of (metadata, function) tuples in dependency order

    Raises:
        ValueError: If circular dependencies are detected
        re.error: If pattern is invalid regex
    """
    if pattern:
        try:
            regex = re.compile(pattern)
        except re.error as e:
            raise ValueError(f"Invalid regex pattern '{pattern}': {e}") from e
        filtered = {k: v for k, v in _CHECK_REGISTRY.items() if regex.search(k)}
    else:
        filtered = _CHECK_REGISTRY

    sorted_checks = []
    resolved = set()
    visiting = set()

    def resolve(name: str):
        if name in resolved:
            return
        if name not in filtered:
            return

        if name in visiting:
            cycle_path = " -> ".join(list(visiting) + [name])
            raise ValueError(
                f"Circular dependency detected: {cycle_path}. "
                f"Check '{name}' depends on itself through this cycle."
            )

        visiting.add(name)
        try:
            metadata, func = filtered[name]
            for dep in metadata.depends_on:
                resolve(dep)

            sorted_checks.append((metadata, func))
            resolved.add(name)
        finally:
            visiting.discard(name)

    for name in filtered:
        resolve(name)

    return sorted_checks


def safe_check_wrapper(
    metadata: CheckMetadata, check_func: Callable
) -> list[CheckResult]:
    """Wrap check execution with error handling.

    Returns a list of CheckResult objects. Most checks return a single result,
    but some checks (like debug.recent_errors) can return multiple results
    for better table formatting.
    """
    try:
        result = check_func()
        if isinstance(result, list):
            return result
        else:
            return [result]
    except Exception as e:
        logger.exception("check_error", check=metadata.name)
        return [
            CheckResult(
                name=metadata.name,
                status=CheckStatus.FAIL,
                message=f"Check raised exception: {type(e).__name__}: {e}",
                severity=metadata.severity,
                details={"exception": str(e), "type": type(e).__name__},
            )
        ]


@check(
    name="environment.claude_installed",
    category="environment",
    severity=CheckSeverity.CRITICAL,
    description="Verify Claude Code is installed",
)
def check_claude_installed() -> CheckResult:
    try:
        claude_path = shutil.which("claude")

        if claude_path:
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
            message=f"Could not determine Claude Code version (exit code: {e.returncode})",
            severity=CheckSeverity.MEDIUM,
            details={"returncode": e.returncode},
        )


@check(
    name="environment.node_version",
    category="environment",
    severity=CheckSeverity.HIGH,
    description="Check Node.js version",
)
def check_node_version() -> CheckResult:
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


@check(
    name="config.settings_file",
    category="config",
    severity=CheckSeverity.CRITICAL,
    description="Verify settings.json exists and is valid JSON",
)
def check_settings_file() -> CheckResult:
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
    except (IOError, OSError, PermissionError) as e:
        return CheckResult(
            name="config.settings_file",
            status=CheckStatus.FAIL,
            message=f"Cannot read settings.json: {e}",
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
    settings_path = Path.home() / ".claude" / "settings.json"

    if settings_path.is_symlink():
        target = settings_path.readlink()
        is_broken = not settings_path.exists()

        if is_broken:
            return CheckResult(
                name="config.settings_writable",
                status=CheckStatus.FAIL,
                message="settings.json is a broken symlink",
                severity=CheckSeverity.CRITICAL,
                fix_command="rm ~/.claude/settings.json && echo '{}' > ~/.claude/settings.json",
                details={"target": str(target), "broken": True},
            )

        return CheckResult(
            name="config.settings_writable",
            status=CheckStatus.FAIL,
            message="settings.json is a symlink (should be mutable file)",
            severity=CheckSeverity.HIGH,
            fix_command="cp -L ~/.claude/settings.json ~/.claude/settings.json.tmp && rm ~/.claude/settings.json && mv ~/.claude/settings.json.tmp ~/.claude/settings.json",
            details={"target": str(target)},
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


@check(
    name="debug.recent_errors",
    category="debug",
    severity=CheckSeverity.MEDIUM,
    description="Scan recent debug logs for errors",
)
def check_debug_log_errors() -> list[CheckResult]:
    debug_dir = Path.home() / ".claude" / "debug"

    if not debug_dir.exists():
        return CheckResult(
            name="debug.recent_errors",
            status=CheckStatus.SKIP,
            message="Debug directory not found",
            severity=CheckSeverity.MEDIUM,
            details={"path": str(debug_dir)},
        )

    try:
        debug_files = sorted(
            [f for f in debug_dir.glob("*.txt") if f.is_file()],
            key=lambda x: x.stat().st_mtime,
            reverse=True,
        )[:5]
    except Exception as e:
        return CheckResult(
            name="debug.recent_errors",
            status=CheckStatus.FAIL,
            message=f"Failed to scan debug directory: {e}",
            severity=CheckSeverity.MEDIUM,
        )

    if not debug_files:
        return CheckResult(
            name="debug.recent_errors",
            status=CheckStatus.SKIP,
            message="No debug log files found",
            severity=CheckSeverity.MEDIUM,
        )

    most_recent = debug_files[0]
    try:
        with open(most_recent) as f:
            first_line = f.readline()
            timestamp_match = re.search(
                r"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})", first_line
            )
            most_recent_time = (
                timestamp_match.group(1) if timestamp_match else "unknown"
            )
    except Exception:
        most_recent_time = "unknown"

    error_counts = {}
    total_errors = 0

    for log_file in debug_files:
        try:
            with open(log_file) as f:
                for line in f:
                    if "[ERROR]" in line:
                        total_errors += 1
                        error_msg = re.sub(
                            r"^\d{4}-\d{2}-\d{2}T[\d:Z.-]+ \[ERROR\] ", "", line.strip()
                        )
                        if "T.filter is not a function" in error_msg:
                            error_counts.setdefault(
                                "T.filter is not a function (repeated)", 0
                            )
                            error_counts["T.filter is not a function (repeated)"] += 1
                        else:
                            error_counts[error_msg] = error_counts.get(error_msg, 0) + 1
        except Exception:
            continue

    if not error_counts:
        return [
            CheckResult(
                name="debug.recent_errors",
                status=CheckStatus.PASS,
                message=f"No errors in recent debug logs (last session: {most_recent_time})",
                severity=CheckSeverity.MEDIUM,
                details={
                    "last_session": most_recent_time,
                    "logs_checked": len(debug_files),
                },
            )
        ]

    top_errors = sorted(
        [(msg, count) for msg, count in error_counts.items() if "T.filter" not in msg],
        key=lambda x: x[1],
        reverse=True,
    )[:5]

    unique_errors = len([msg for msg in error_counts.keys() if "T.filter" not in msg])
    t_filter_count = error_counts.get("T.filter is not a function (repeated)", 0)

    summary_parts = []
    summary_parts.append(f"{total_errors} errors")
    summary_parts.append(f"{unique_errors} types")
    if t_filter_count > 0:
        summary_parts.append(f"{t_filter_count}× T.filter excluded")
    summary_parts.append(f"last: {most_recent_time}")

    message = f"Found {', '.join(summary_parts)}"

    status = CheckStatus.WARN if top_errors else CheckStatus.PASS

    results = [
        CheckResult(
            name="debug.recent_errors",
            status=status,
            message=message,
            severity=CheckSeverity.MEDIUM,
            details={
                "last_session": most_recent_time,
                "logs_checked": len(debug_files),
                "total_errors": total_errors,
                "unique_errors": unique_errors,
                "t_filter_count": t_filter_count,
            },
        )
    ]

    for idx, (error_msg, count) in enumerate(top_errors, 1):
        preview = f"error{idx}"
        display_msg = f"{count}× {error_msg}"
        if len(display_msg) > 100:
            display_msg = display_msg[:97] + "..."

        results.append(
            CheckResult(
                name=f"debug.recent_errors:{preview}",
                status=CheckStatus.WARN,
                message=display_msg,
                severity=CheckSeverity.MEDIUM,
            )
        )

    return results


@check(
    name="plugin.marketplace_dir",
    category="plugin",
    severity=CheckSeverity.MEDIUM,
    description="Verify marketplaces directory exists",
)
def check_marketplace_dir() -> CheckResult:
    marketplace_dir = PLUGIN_MARKETPLACE_DIR

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
    cache_dir = PLUGIN_CACHE_DIR

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
    plugin_dirs = [PLUGIN_MARKETPLACE_DIR, PLUGIN_CACHE_DIR]

    broken = []
    for base_dir in plugin_dirs:
        if not base_dir.exists():
            continue

        for path in base_dir.rglob("*"):
            if path.is_symlink() and not path.exists():
                broken.append(str(path))

    if broken:
        total_count = len(broken)
        shown_count = min(5, total_count)
        message = (
            f"Found {total_count} broken symlink(s)"
            if total_count <= 5
            else f"Found {total_count} broken symlinks (showing first {shown_count})"
        )
        quoted_paths = [shlex.quote(path) for path in broken[:5]]
        return CheckResult(
            name="plugin.broken_symlinks",
            status=CheckStatus.WARN,
            message=message,
            severity=CheckSeverity.MEDIUM,
            details={"broken_links": broken[:5] if len(broken) > 5 else broken},
            fix_command=f"rm {' '.join(quoted_paths)}",
        )

    return CheckResult(
        name="plugin.broken_symlinks",
        status=CheckStatus.PASS,
        message="No broken symlinks found",
        severity=CheckSeverity.MEDIUM,
    )


def apply_fixes(results: list[CheckResult], dry_run: bool) -> list[CheckResult]:
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
                            shlex.split(result.fix_command),
                            shell=False,
                            check=True,
                            capture_output=True,
                            text=True,
                        )
                        console_err.print(f"[green]✓ Fixed: {result.name}[/green]")
                        result.status = CheckStatus.PASS
                        result.message += " (automatically fixed)"
                    except subprocess.CalledProcessError as e:
                        console_err.print(f"[red]✗ Fix failed: {result.name}[/red]")
                        logger.error(
                            "fix_command_error", check=result.name, error=e.stderr
                        )
            elif result.fix_function:
                if dry_run:
                    console_err.print(
                        f"[blue]Would call fix function for: {result.name}[/blue]"
                    )
                else:
                    try:
                        console_err.print(f"[cyan]Fixing {result.name}...[/cyan]")
                        success = result.fix_function()
                        if success:
                            console_err.print(f"[green]✓ Fixed: {result.name}[/green]")
                            result.status = CheckStatus.PASS
                            result.message += " (automatically fixed)"
                        else:
                            console_err.print(
                                f"[yellow]⚠ Fix returned False: {result.name}[/yellow]"
                            )
                    except Exception as e:
                        console_err.print(f"[red]✗ Fix failed: {result.name}[/red]")
                        logger.error(
                            "fix_function_error", check=result.name, error=str(e)
                        )

        fixed_results.append(result)

    return fixed_results


class ToolCall(BaseModel):
    tool_name: str
    timestamp: str
    key_params: str
    session_id: str
    was_approved: bool


class ToolAuditReport(BaseModel):
    start_date: Optional[str]
    end_date: Optional[str]
    total_conversations: int
    total_tool_calls: int
    unique_tool_calls: int
    tool_calls: list[dict[str, Any]]


def extract_key_params(tool_name: str, tool_input: dict[str, Any]) -> str:
    if tool_name == "Bash":
        cmd = tool_input.get("command", "")
        return cmd[:100] if len(cmd) <= 100 else cmd[:97] + "..."
    elif tool_name in ("Edit", "Write", "Read"):
        return tool_input.get("file_path", "")
    elif tool_name == "Glob":
        return tool_input.get("pattern", "")
    elif tool_name == "Grep":
        return tool_input.get("pattern", "")
    elif tool_name == "Task":
        return tool_input.get("subagent_type", "")
    elif tool_name == "Skill":
        return tool_input.get("skill", "")
    else:
        if tool_input:
            first_key = next(iter(tool_input.keys()), "")
            first_val = tool_input.get(first_key, "")
            return f"{first_key}={first_val}"[:50]
        return ""


def parse_relative_date(date_str: str) -> str:
    """Parse relative date strings to YYYY-MM-DD format.

    Supports pandas-style relative dates:
        -NM: N minutes ago (e.g., '-30M' = 30 minutes ago) - uppercase M
        -Nh: N hours ago (e.g., '-1h' = 1 hour ago, '-12h' = 12 hours ago)
        -Nd: N days ago (e.g., '-1d' = yesterday, '-7d' = 7 days ago)
        -Nw: N weeks ago (e.g., '-1w' = 1 week ago)
        -Nm: N months ago (e.g., '-1m' = 1 month ago) - lowercase m
        -Ny: N years ago (e.g., '-1y' = 1 year ago)

    If the string is already in YYYY-MM-DD format, returns it unchanged.

    Raises:
        click.BadParameter: If the date format is invalid
    """
    if not date_str:
        return date_str

    if re.match(r"^\d{4}-\d{2}-\d{2}$", date_str):
        return date_str

    match = re.match(r"^-(\d+)([MhDdwmy])$", date_str)
    if not match:
        raise click.BadParameter(
            f"Invalid date format: '{date_str}'. "
            f"Use YYYY-MM-DD or relative format like -1h, -30M, -7d, -1w, -1m, -1y"
        )

    amount = int(match.group(1))
    unit = match.group(2)

    now = datetime.now()
    if unit == "M":  # Minutes (uppercase)
        delta = relativedelta(minutes=amount)
    elif unit == "h":  # Hours
        delta = relativedelta(hours=amount)
    elif unit in ("d", "D"):  # Days (allow both cases)
        delta = relativedelta(days=amount)
    elif unit == "w":  # Weeks
        delta = relativedelta(weeks=amount)
    elif unit == "m":  # Months (lowercase)
        delta = relativedelta(months=amount)
    elif unit == "y":  # Years
        delta = relativedelta(years=amount)

    target_date = now - delta
    return target_date.strftime("%Y-%m-%d")


def generate_permission_pattern(
    tool_name: str, key_params: str, existing_patterns: Optional[set[str]] = None
) -> Optional[str]:
    """Generate a permission pattern from a tool call.

    Returns a pattern suitable for Claude Code's permissions.allow list.
    Follows the format used in claude.nix configuration.
    Returns None for patterns that should be skipped (overly specific or unwanted).

    If fine-grained variants of a command exist in existing_patterns
    (e.g., Bash(git add:*), Bash(git commit:*)), generates a subcommand
    pattern instead of a general pattern.
    """
    if existing_patterns is None:
        existing_patterns = set()

    if tool_name == "Bash":
        parts = key_params.split()
        cmd = parts[0] if parts else ""
        if not cmd:
            return "Bash"

        if (
            cmd.startswith("/")
            or cmd.startswith("./")
            or cmd.startswith("~/")
            or "/" in cmd
        ):
            return None

        if "=" in cmd:
            return None

        # Skip commands that should never be suggested
        skip_commands = {"python3", "npx", "for", "mv", "rm", "cp", "pkill", "cd", "curl", "chmod", "source"}
        if cmd in skip_commands:
            return None

        # Check if fine-grained patterns exist for this command
        has_fine_grained = any(
            p.startswith(f"Bash({cmd} ") for p in existing_patterns
        )

        if has_fine_grained and len(parts) > 1:
            # Extract subcommand (skip flags to find the actual subcommand)
            subcommand = None
            for part in parts[1:]:
                if not part.startswith("-"):
                    subcommand = part
                    break

            if subcommand:
                # Skip certain git subcommands
                skip_git_subcommands = {"revert", "restore", "push", "checkout", "reset"}
                if cmd == "git" and subcommand in skip_git_subcommands:
                    return None

                # Skip certain gh subcommands
                skip_gh_subcommands = {"pr"}
                if cmd == "gh" and subcommand in skip_gh_subcommands:
                    return None

                return f"Bash({cmd} {subcommand}:*)"

        # Return simple pattern if no fine-grained variants exist
        return f"Bash({cmd}:*)"

    elif tool_name == "Edit":
        return None

    elif tool_name in ("Write", "Read"):
        if key_params.startswith("/Users/"):
            parts = key_params.split("/")
            if len(parts) >= 4:
                base_path = "/".join(parts[1:4])
                return f"{tool_name}(//{base_path}/**)"
        return tool_name
    elif tool_name == "Glob":
        return "Glob"
    elif tool_name == "Grep":
        return "Grep"
    elif tool_name == "Task":
        return "Task"
    elif tool_name == "Skill":
        return "Skill"
    elif tool_name == "TodoWrite":
        return "TodoWrite"
    elif tool_name == "WebFetch":
        return "WebFetch"
    elif tool_name == "WebSearch":
        return "WebSearch"
    elif tool_name == "AskUserQuestion":
        return "AskUserQuestion"
    elif tool_name == "NotebookEdit":
        return "NotebookEdit"
    elif tool_name.startswith("mcp__"):
        parts = tool_name.split("__")
        if len(parts) >= 2:
            return f"{parts[0]}__{parts[1]}__*"
        return tool_name
    else:
        return tool_name


def load_existing_allow_list() -> set[str]:
    settings_file = Path.home() / ".claude" / "settings.json"
    try:
        with open(settings_file) as f:
            settings = json.load(f)
            allow_list = settings.get("permissions", {}).get("allow", [])
            return set(allow_list)
    except (FileNotFoundError, json.JSONDecodeError):
        return set()


def would_tool_call_be_permitted(
    tool_name: str, key_params: str, existing_patterns: set[str]
) -> bool:
    """Check if a specific tool call would be permitted by existing allow list.

    Implements Claude Code's documented permission matching logic:
    https://code.claude.com/docs/en/settings#permission-pattern-matching-syntax
    """
    if tool_name in existing_patterns:
        return True

    if tool_name == "Bash" and key_params:
        for pattern in existing_patterns:
            if not pattern.startswith("Bash("):
                continue

            pattern_cmd = pattern[5:-1]

            if pattern_cmd.endswith(":*"):
                prefix = pattern_cmd[:-2]
                if key_params == prefix or key_params.startswith(prefix + " "):
                    return True

            elif "*" in pattern_cmd:
                import re

                regex_pattern = "^" + re.escape(pattern_cmd).replace(r"\*", ".*") + "$"
                if re.match(regex_pattern, key_params):
                    return True

            elif pattern_cmd == key_params:
                return True

    elif tool_name in ("Read", "Write", "Edit") and key_params:
        for pattern in existing_patterns:
            if not pattern.startswith(f"{tool_name}("):
                continue

            if pattern.endswith("/**)"):
                base_path = pattern[len(tool_name) + 3 : -4]
                if (
                    key_params.startswith("/" + base_path + "/")
                    or key_params == "/" + base_path
                ):
                    return True
            elif pattern.endswith(")"):
                file_path = pattern[len(tool_name) + 1 : -1]
                if key_params == file_path:
                    return True

    elif tool_name.startswith("mcp__"):
        parts = tool_name.split("__")
        if len(parts) >= 2:
            wildcard_pattern = f"{parts[0]}__{parts[1]}__*"
            if wildcard_pattern in existing_patterns:
                return True

    return False


def extract_content_items(content: Any) -> list[dict]:
    """Extract content items from message content.

    Handles both legacy format (string) and modern format (list of blocks).
    Based on Simon Willison's claude-code-transcripts parser.
    """
    if isinstance(content, str):
        return [{"type": "text", "text": content}]
    elif isinstance(content, list):
        return [item for item in content if isinstance(item, dict)]
    else:
        return []


def parse_conversation_file(file_path: Path) -> list[ToolCall]:
    tool_calls = []
    tool_use_map = {}

    try:
        with open(file_path) as f:
            for line in f:
                try:
                    entry = json.loads(line)
                    entry_type = entry.get("type")

                    if entry_type not in ("user", "assistant"):
                        continue

                    if entry_type == "assistant":
                        message = entry.get("message", {})
                        if not isinstance(message, dict):
                            continue

                        # Use helper to handle both legacy and modern content formats
                        content_items = extract_content_items(message.get("content"))
                        timestamp = entry.get("timestamp", "")
                        session_id = entry.get("sessionId", "")

                        for item in content_items:
                            if item.get("type") == "tool_use":
                                tool_id = item.get("id")
                                tool_name = item.get("name")
                                tool_input = item.get("input", {})

                                if tool_id and tool_name:
                                    tool_use_map[tool_id] = {
                                        "name": tool_name,
                                        "input": tool_input,
                                        "timestamp": timestamp,
                                        "session_id": session_id,
                                    }

                    # Extract tool_result entries from user messages to determine approval
                    elif entry_type == "user":
                        message = entry.get("message", {})
                        if not isinstance(message, dict):
                            continue

                        # Use helper to handle both legacy and modern content formats
                        content_items = extract_content_items(message.get("content"))

                        for item in content_items:
                            if item.get("type") == "tool_result":
                                tool_use_id = item.get("tool_use_id")
                                tool_result = entry.get("toolUseResult", {})

                                # Ensure tool_result is a dict (handle legacy formats)
                                if not isinstance(tool_result, dict):
                                    tool_result = {}

                                # Check if tool was approved (success=True means it ran)
                                # If there's an error about user denial, was_approved=False
                                was_approved = True
                                if not tool_result.get("success", True):
                                    # Check if it was explicitly denied
                                    content_text = str(item.get("content", ""))
                                    if (
                                        "doesn't want to proceed" in content_text
                                        or "denied" in content_text.lower()
                                    ):
                                        was_approved = False

                                if tool_use_id in tool_use_map:
                                    tool_info = tool_use_map[tool_use_id]
                                    key_params = extract_key_params(
                                        tool_info["name"], tool_info["input"]
                                    )

                                    tool_calls.append(
                                        ToolCall(
                                            tool_name=tool_info["name"],
                                            timestamp=tool_info["timestamp"],
                                            key_params=key_params,
                                            session_id=tool_info["session_id"],
                                            was_approved=was_approved,
                                        )
                                    )

                except (json.JSONDecodeError, AttributeError, KeyError, TypeError):
                    # Skip malformed lines or entries with unexpected structure
                    continue

    except Exception as e:
        # Log file-level errors (e.g., file not found, permission denied)
        logger.warning("conversation_file_error", file=str(file_path), error=str(e))

    return tool_calls


def audit_tools(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    project_path: Optional[str] = None,
) -> ToolAuditReport:
    """Audit tool calls from conversation history."""
    if project_path:
        projects_dir = Path(project_path)
    else:
        projects_dir = Path.home() / ".claude" / "projects"

    if not projects_dir.exists():
        return ToolAuditReport(
            start_date=start_date,
            end_date=end_date,
            total_conversations=0,
            total_tool_calls=0,
            unique_tool_calls=0,
            tool_calls=[],
        )

    # Find all conversation files
    conv_files = list(projects_dir.rglob("*.jsonl"))

    # Parse conversations and collect tool calls
    all_tool_calls = []
    for conv_file in conv_files:
        tool_calls = parse_conversation_file(conv_file)
        all_tool_calls.extend(tool_calls)

    # Filter by date if specified
    filtered_calls = []
    for call in all_tool_calls:
        if not call.was_approved:
            continue

        if start_date or end_date:
            call_date = call.timestamp.split("T")[0] if "T" in call.timestamp else ""
            if start_date and call_date < start_date:
                continue
            if end_date and call_date > end_date:
                continue

        filtered_calls.append(call)

    unique_calls = {}
    for call in filtered_calls:
        key = f"{call.tool_name}:{call.key_params}"
        if key not in unique_calls:
            unique_calls[key] = {
                "tool_name": call.tool_name,
                "key_params": call.key_params,
                "count": 1,
                "first_seen": call.timestamp,
                "last_seen": call.timestamp,
                "sessions": {call.session_id},
            }
        else:
            unique_calls[key]["count"] += 1
            unique_calls[key]["sessions"].add(call.session_id)
            if call.timestamp < unique_calls[key]["first_seen"]:
                unique_calls[key]["first_seen"] = call.timestamp
            if call.timestamp > unique_calls[key]["last_seen"]:
                unique_calls[key]["last_seen"] = call.timestamp

    tool_call_list = []
    for call_data in unique_calls.values():
        call_data["session_count"] = len(call_data["sessions"])
        call_data["sessions"] = list(call_data["sessions"])
        tool_call_list.append(call_data)

    tool_call_list.sort(key=lambda x: x["count"], reverse=True)

    return ToolAuditReport(
        start_date=start_date,
        end_date=end_date,
        total_conversations=len(conv_files),
        total_tool_calls=len(filtered_calls),
        unique_tool_calls=len(unique_calls),
        tool_calls=tool_call_list,
    )


def format_audit_rich(report: ToolAuditReport) -> None:
    console.print("\n[bold]Claude Code Tool Audit Report[/bold]")
    if report.start_date:
        console.print(f"Date range: {report.start_date} to {report.end_date or 'now'}")
    console.print(f"Conversations scanned: {report.total_conversations}")
    console.print(f"Approved tool calls: {report.total_tool_calls}")
    console.print(f"Unique tool calls: {report.unique_tool_calls}\n")

    if not report.tool_calls:
        console.print("[yellow]No approved tool calls found in date range[/yellow]")
        return

    table = Table(title="Tool Usage Statistics")
    table.add_column("Tool", style="cyan", no_wrap=True)
    table.add_column("Parameters", style="dim")
    table.add_column("Count", justify="right", style="bold")
    table.add_column("Sessions", justify="right")
    table.add_column("First Seen", style="dim")
    table.add_column("Last Seen", style="dim")

    for call in report.tool_calls[:50]:
        params = call["key_params"]
        if len(params) > 60:
            params = params[:57] + "..."

        first_seen = (
            call["first_seen"].split("T")[0]
            if "T" in call["first_seen"]
            else call["first_seen"]
        )
        last_seen = (
            call["last_seen"].split("T")[0]
            if "T" in call["last_seen"]
            else call["last_seen"]
        )

        table.add_row(
            call["tool_name"],
            params,
            str(call["count"]),
            str(call["session_count"]),
            first_seen,
            last_seen,
        )

    console.print(table)

    if len(report.tool_calls) > 50:
        console.print(
            f"\n[dim]Showing top 50 of {len(report.tool_calls)} unique tool calls[/dim]"
        )


def format_audit_json(report: ToolAuditReport) -> None:
    """Format tool audit report as JSON."""
    print(report.model_dump_json(indent=2))


# CLI


@click.group(context_settings={"help_option_names": ["-h", "--help"]})
def cli():
    """Claude Code diagnostic and audit tool."""
    pass


@cli.command(name="check")
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
@click.option("--fix", is_flag=True, help="Automatically attempt to fix issues")
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
def check_command(
    format: str,
    filter: Optional[str],
    fix: bool,
    dry_run: bool,
    verbose: int,
    log_level: str,
):
    """Run diagnostic health checks on Claude Code installation.

    Examples:

        claude-doctor check                          # Run all checks

        claude-doctor check --filter "plugin.*"      # Only plugin checks

        claude-doctor check --dry-run --fix          # Preview fixes

        claude-doctor check --fix                    # Fix issues automatically

        claude-doctor check -vvv                     # Maximum verbosity
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
    total_checks = len(checks)

    for idx, (metadata, check_func) in enumerate(checks, 1):
        # Show progress (only for rich output, not JSON)
        if format == "rich":
            console_err.print(
                f"[dim]Running check {idx}/{total_checks}: {metadata.name}[/dim]"
            )

        # Skip if dependency failed
        if any(dep in skipped for dep in metadata.depends_on):
            check_results = [
                CheckResult(
                    name=metadata.name,
                    status=CheckStatus.SKIP,
                    message="Skipped due to failed dependency",
                    severity=metadata.severity,
                )
            ]
            skipped.add(metadata.name)
        else:
            logger.info(f"Running check: {metadata.name}")
            check_results = safe_check_wrapper(metadata, check_func)
            # Mark as skipped if the main check failed critically
            if any(
                r.status == CheckStatus.FAIL
                and r.name == metadata.name
                and metadata.severity == CheckSeverity.CRITICAL
                for r in check_results
            ):
                skipped.add(metadata.name)

        results.extend(check_results)

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


@cli.command(name="audit-tools")
@click.option(
    "--format",
    "-f",
    type=click.Choice(["rich", "json"], case_sensitive=False),
    default="rich",
    help="Output format",
)
@click.option(
    "--start-date",
    type=str,
    help="Start date filter (YYYY-MM-DD or relative like '-1h', '-7d', '-1w', '-1m')",
)
@click.option(
    "--end-date",
    type=str,
    help="End date filter (YYYY-MM-DD or relative like '-1h', '-1d', '-2w')",
)
@click.option(
    "--project",
    type=str,
    help="Custom project path (default: ~/.claude/projects)",
)
@click.option(
    "--suggest-permissions",
    is_flag=True,
    help="Suggest permission patterns for allow list based on approved tool calls",
)
def audit_tools_command(
    format: str,
    start_date: Optional[str],
    end_date: Optional[str],
    project: Optional[str],
    suggest_permissions: bool,
):
    """Audit approved tool calls from conversation history.

    Analyzes past conversations and reports unique tool calls that were
    approved (not denied by user). Tool calls are grouped by tool name
    and key parameters.

    Examples:

        claude-doctor audit-tools                             # All time

        claude-doctor audit-tools --start-date 2026-01-01     # Since date

        claude-doctor audit-tools --start-date -1h            # Last hour

        claude-doctor audit-tools --start-date -12h           # Last 12 hours

        claude-doctor audit-tools --start-date -7d            # Last 7 days

        claude-doctor audit-tools --start-date -1w --end-date -1d  # Last week

        claude-doctor audit-tools --start-date -1m            # Last month

        claude-doctor audit-tools --format json > audit.json  # JSON export
    """
    # Parse relative date strings (e.g., '-1d', '-7d', '-1w')
    if start_date:
        start_date = parse_relative_date(start_date)
    if end_date:
        end_date = parse_relative_date(end_date)

    report = audit_tools(start_date=start_date, end_date=end_date, project_path=project)

    if suggest_permissions:
        # Generate permission pattern suggestions
        existing_patterns = load_existing_allow_list()
        pattern_counts: dict[str, int] = {}

        # Filter tool calls to only those that would be DENIED by existing patterns
        # Then count occurrences of patterns needed for those denied calls
        for tool_call in report.tool_calls:
            # Check if this specific tool call would be permitted
            if would_tool_call_be_permitted(
                tool_call["tool_name"], tool_call["key_params"], existing_patterns
            ):
                # Skip - already permitted
                continue

            # Generate pattern for this denied tool call
            pattern = generate_permission_pattern(
                tool_call["tool_name"], tool_call["key_params"], existing_patterns
            )
            # Skip None patterns (overly specific or unwanted patterns)
            if pattern is not None:
                pattern_counts[pattern] = (
                    pattern_counts.get(pattern, 0) + tool_call["count"]
                )

        # All patterns in pattern_counts are for tool calls that would be denied
        new_patterns = pattern_counts
        console = Console()

        if format == "json":
            # JSON output for suggestions
            suggestions = {
                "existing_patterns_count": len(existing_patterns),
                "new_patterns_count": len(new_patterns),
                "suggestions": [
                    {"pattern": pattern, "usage_count": count}
                    for pattern, count in sorted(
                        new_patterns.items(), key=lambda x: x[1], reverse=True
                    )
                ],
            }
            console.print_json(data=suggestions)
        else:
            # Rich table output for suggestions
            console.print(
                f"\n[bold]Permission Pattern Suggestions[/bold]"
                f"\nExisting patterns in allow list: {len(existing_patterns)}"
                f"\nNew patterns to consider: {len(new_patterns)}\n"
            )

            if new_patterns:
                table = Table(title="Suggested Permission Patterns")
                table.add_column("Pattern", style="cyan")
                table.add_column("Usage Count", style="green", justify="right")

                for pattern, count in sorted(
                    new_patterns.items(), key=lambda x: x[1], reverse=True
                ):
                    table.add_row(pattern, str(count))

                console.print(table)
                console.print(
                    "\n[dim]Add these patterns to permissions.allow in ~/.config/nix/home-manager/modules/coding-agents/claude/claude.nix[/dim]"
                )
            else:
                console.print(
                    "[green]✓[/green] All approved tool calls are already permitted!"
                )
    else:
        # Regular audit output
        if format == "json":
            format_audit_json(report)
        else:
            format_audit_rich(report)


def main():
    """Main entry point with default command support."""
    import sys

    # If no subcommand provided, default to 'check' for backward compatibility
    if len(sys.argv) == 1 or (len(sys.argv) > 1 and sys.argv[1].startswith("-")):
        sys.argv.insert(1, "check")

    cli()


if __name__ == "__main__":
    main()
