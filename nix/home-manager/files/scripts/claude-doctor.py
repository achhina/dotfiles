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
