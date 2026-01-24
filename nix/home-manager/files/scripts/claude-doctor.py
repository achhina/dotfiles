#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["click", "structlog", "rich", "pydantic", "claude-code-transcripts"]
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
from pydantic import BaseModel, ConfigDict, Field
from rich.console import Console
from rich.table import Table

"""
Diagnostic tool for Claude Code installations.

Provides comprehensive health checks across environment, configuration,
plugins, MCP servers, permissions, performance, and hooks.
"""


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


# Output Formatting


def format_rich(report: DiagnosticReport) -> None:
    """Format report as Rich table."""
    # Summary
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

    # Group by category
    by_category: dict[str, list[CheckResult]] = {}
    for result in report.results:
        parts = result.name.split(".", 1)
        category = parts[0] if parts else "unknown"
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
            parts = result.name.split(".", 1)
            check_name = parts[1] if len(parts) > 1 else result.name
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
        console.print("\nRun with [cyan]--fix[/cyan] to apply fixes automatically\n")


def format_json(report: DiagnosticReport) -> None:
    """Format report as JSON."""
    print(
        report.model_dump_json(
            indent=2, exclude={"results": {"__all__": {"fix_function"}}}
        )
    )


# Claude Code directories
CLAUDE_HOME = Path.home() / ".claude"
PLUGIN_MARKETPLACE_DIR = CLAUDE_HOME / "plugins" / "marketplaces"
PLUGIN_CACHE_DIR = CLAUDE_HOME / "plugins" / "cache"


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

    # Topological sort by dependencies with cycle detection
    sorted_checks = []
    resolved = set()
    visiting = set()

    def resolve(name: str):
        if name in resolved:
            return
        if name not in filtered:
            return

        if name in visiting:
            # Circular dependency detected
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
    """Check if settings.json is writable (not stuck as symlink)."""
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


# Plugin Checks


@check(
    name="plugin.marketplace_dir",
    category="plugin",
    severity=CheckSeverity.MEDIUM,
    description="Verify marketplaces directory exists",
)
def check_marketplace_dir() -> CheckResult:
    """Check if marketplaces directory exists."""
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
    """Check if plugin cache directory is accessible."""
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
    """Find broken symlinks in plugin directories."""
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


# Tool Audit Models and Functions


class ToolCall(BaseModel):
    """Represents a tool call with key parameters."""

    tool_name: str
    timestamp: str
    key_params: str
    session_id: str
    was_approved: bool


class ToolAuditReport(BaseModel):
    """Summary of tool call audit."""

    start_date: Optional[str]
    end_date: Optional[str]
    total_conversations: int
    total_tool_calls: int
    unique_tool_calls: int
    tool_calls: list[dict[str, Any]]


def extract_key_params(tool_name: str, tool_input: dict[str, Any]) -> str:
    """Extract key parameters from tool input for uniqueness determination."""
    if tool_name == "Bash":
        cmd = tool_input.get("command", "")
        # Truncate long commands but keep meaningful parts
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
        # For other tools, use first parameter or empty
        if tool_input:
            first_key = next(iter(tool_input.keys()), "")
            first_val = tool_input.get(first_key, "")
            return f"{first_key}={first_val}"[:50]
        return ""


def extract_content_items(content: Any) -> list[dict]:
    """Extract content items from message content.

    Handles both legacy format (string) and modern format (list of blocks).
    Based on Simon Willison's claude-code-transcripts parser.
    """
    if isinstance(content, str):
        # Legacy format: content is a plain string
        return [{"type": "text", "text": content}]
    elif isinstance(content, list):
        # Modern format: content is a list of blocks
        return [item for item in content if isinstance(item, dict)]
    else:
        return []


def parse_conversation_file(file_path: Path) -> list[ToolCall]:
    """Parse a conversation JSONL file and extract approved tool calls."""
    tool_calls = []
    tool_use_map = {}  # Map tool_use_id to tool details

    try:
        with open(file_path) as f:
            for line in f:
                try:
                    entry = json.loads(line)
                    entry_type = entry.get("type")

                    # Skip non-conversation entries
                    if entry_type not in ("user", "assistant"):
                        continue

                    # Extract tool_use entries from assistant messages
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
                                    if "doesn't want to proceed" in content_text or "denied" in content_text.lower():
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
            continue  # Skip denied tool calls

        if start_date or end_date:
            call_date = call.timestamp.split("T")[0] if "T" in call.timestamp else ""
            if start_date and call_date < start_date:
                continue
            if end_date and call_date > end_date:
                continue

        filtered_calls.append(call)

    # Group by tool + key params for uniqueness
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

    # Convert to list and add session count
    tool_call_list = []
    for call_data in unique_calls.values():
        call_data["session_count"] = len(call_data["sessions"])
        call_data["sessions"] = list(call_data["sessions"])  # Convert set to list
        tool_call_list.append(call_data)

    # Sort by count (most used first)
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
    """Format tool audit report as Rich table."""
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

    for call in report.tool_calls[:50]:  # Limit to top 50
        # Truncate long parameters
        params = call["key_params"]
        if len(params) > 60:
            params = params[:57] + "..."

        # Format dates
        first_seen = call["first_seen"].split("T")[0] if "T" in call["first_seen"] else call["first_seen"]
        last_seen = call["last_seen"].split("T")[0] if "T" in call["last_seen"] else call["last_seen"]

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
        console.print(f"\n[dim]Showing top 50 of {len(report.tool_calls)} unique tool calls[/dim]")


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
    help="Start date filter (YYYY-MM-DD)",
)
@click.option(
    "--end-date",
    type=str,
    help="End date filter (YYYY-MM-DD)",
)
@click.option(
    "--project",
    type=str,
    help="Custom project path (default: ~/.claude/projects)",
)
def audit_tools_command(
    format: str,
    start_date: Optional[str],
    end_date: Optional[str],
    project: Optional[str],
):
    """Audit approved tool calls from conversation history.

    Analyzes past conversations and reports unique tool calls that were
    approved (not denied by user). Tool calls are grouped by tool name
    and key parameters.

    Examples:

        claude-doctor audit-tools                             # All time

        claude-doctor audit-tools --start-date 2026-01-01     # Since date

        claude-doctor audit-tools --start-date 2026-01-01 --end-date 2026-01-31

        claude-doctor audit-tools --format json > audit.json  # JSON export
    """
    report = audit_tools(start_date=start_date, end_date=end_date, project_path=project)

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
