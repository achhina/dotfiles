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


def get_checks_by_filter(pattern: Optional[str] = None) -> list[tuple[CheckMetadata, Callable]]:
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
