#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["click", "structlog", "rich", "pydantic"]
# ///

"""
Git worktree manager for multi-project workflows.

Manages git worktrees in a centralized directory structure:
~/worktrees/<project>/<worktree-name>/
"""

import logging
import subprocess
import sys
from pathlib import Path
from typing import Optional

import click
import structlog
from pydantic import BaseModel, ConfigDict
from rich.console import Console
from rich.table import Table

# Constants
DEFAULT_WORKTREE_BASE = Path.home() / "worktrees"
DEFAULT_LOG_LEVEL = "warning"

# Global console (logger configured per-invocation)
console = Console()
console_err = Console(stderr=True)
logger = structlog.get_logger()


class WorktreeInfo(BaseModel):
    """Represents a git worktree with its metadata."""

    model_config = ConfigDict(frozen=True)

    path: Path
    branch: str
    project: str
    is_current_repo: bool


class GitRepo(BaseModel):
    """Represents the current git repository context."""

    model_config = ConfigDict(frozen=True)

    root: Path
    project_name: str


class WorktreesInfo(BaseModel):
    """Container for worktree list with metadata."""

    model_config = ConfigDict(frozen=True)

    worktrees: list[WorktreeInfo]
    is_global_scope: bool
    current_project: Optional[str] = None

    @property
    def total_count(self) -> int:
        """Total number of worktrees."""
        return len(self.worktrees)


def format_worktrees(worktrees_info: WorktreesInfo, format: str) -> None:
    """Format and display worktrees in the specified format."""
    if format == "json":
        # Use Pydantic's built-in serialization for the entire container
        print(worktrees_info.model_dump_json(indent=2))
    elif format == "rich":
        # Create rich table
        table = Table(title="Git Worktrees")
        table.add_column("Project", style="cyan")
        table.add_column("Branch", style="green")
        table.add_column("Path", style="blue")

        for wt in worktrees_info.worktrees:
            table.add_row(wt.project, wt.branch, str(wt.path))

        console.print(table)


def get_git_root(cwd: Path = Path.cwd()) -> Optional[Path]:
    """Find git root using 'git rev-parse --show-toplevel'."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=cwd,
            capture_output=True,
            text=True,
            check=True,
        )
        return Path(result.stdout.strip())
    except subprocess.CalledProcessError:
        return None


def get_main_worktree(cwd: Path = Path.cwd()) -> Optional[Path]:
    """Find the main worktree (bare repository) for the current git repo."""
    try:
        result = subprocess.run(
            ["git", "worktree", "list", "--porcelain"],
            cwd=cwd,
            capture_output=True,
            text=True,
            check=True,
        )

        # Parse porcelain output - first worktree is always the main one
        for line in result.stdout.splitlines():
            if line.startswith("worktree "):
                return Path(line.split(" ", 1)[1])

        return None
    except subprocess.CalledProcessError:
        return None


def get_project_name(cwd: Path = Path.cwd()) -> Optional[str]:
    """
    Get the project name from git remote origin URL.

    Falls back to main worktree directory name if no remote exists.
    Returns None if not in a git repository.
    """
    try:
        # Try to get remote origin URL
        result = subprocess.run(
            ["git", "config", "--get", "remote.origin.url"],
            cwd=cwd,
            capture_output=True,
            text=True,
            check=True,
        )

        remote_url = result.stdout.strip()

        # Parse project name from various URL formats:
        # - https://github.com/user/repo.git
        # - git@github.com:user/repo.git
        # - /path/to/repo.git

        # Remove .git suffix if present
        if remote_url.endswith(".git"):
            remote_url = remote_url[:-4]

        # Extract last component (repo name)
        # Works for both URL paths and SSH format
        project_name = remote_url.rstrip("/").split("/")[-1].split(":")[-1]

        if project_name:
            return project_name

    except subprocess.CalledProcessError:
        # No remote.origin.url configured, fall back to directory name
        pass

    # Fallback: use main worktree directory name
    main_worktree = get_main_worktree(cwd)
    if main_worktree:
        return main_worktree.name

    return None


def validate_worktree_name(name: str) -> None:
    """Ensure worktree name is valid (no slashes, not '.', not '..')."""
    if "/" in name or "\\" in name:
        raise click.BadParameter("Worktree name cannot contain slashes")
    if name in (".", ".."):
        raise click.BadParameter("Worktree name cannot be '.' or '..'")
    if not name.strip():
        raise click.BadParameter("Worktree name cannot be empty")


def discover_worktrees(
    base_dir: Path, current_repo: Optional[GitRepo]
) -> list[WorktreeInfo]:
    """Scan ~/worktrees/ and parse 'git worktree list' for each project."""
    worktrees = []

    if not base_dir.exists():
        return worktrees

    for project_dir in base_dir.iterdir():
        if not project_dir.is_dir():
            continue

        project_name = project_dir.name

        # Find the main repo for this project (the one not in ~/worktrees/)
        main_repo = None
        for worktree_dir in project_dir.iterdir():
            if worktree_dir.is_dir():
                git_root = get_git_root(worktree_dir)
                if git_root and git_root != worktree_dir:
                    main_repo = git_root
                    break

        if not main_repo:
            # Try to find worktrees from any worktree in this project
            for worktree_dir in project_dir.iterdir():
                if worktree_dir.is_dir():
                    main_repo = worktree_dir
                    break

        if not main_repo:
            continue

        # Get worktree list from git
        try:
            result = subprocess.run(
                ["git", "worktree", "list", "--porcelain"],
                cwd=main_repo,
                capture_output=True,
                text=True,
                check=True,
            )

            # Parse porcelain output
            current_worktree = {}
            for line in result.stdout.splitlines():
                if line.startswith("worktree "):
                    if current_worktree:
                        path = Path(current_worktree["worktree"])
                        if (
                            path.parent.parent == base_dir
                            and path.parent.name == project_name
                        ):
                            is_current = (
                                current_repo is not None
                                and current_repo.project_name == project_name
                            )
                            worktrees.append(
                                WorktreeInfo(
                                    path=path,
                                    branch=current_worktree.get("branch", "HEAD"),
                                    project=project_name,
                                    is_current_repo=is_current,
                                )
                            )
                    current_worktree = {"worktree": line.split(" ", 1)[1]}
                elif line.startswith("branch "):
                    # Extract branch name (format: "refs/heads/branch-name")
                    branch_ref = line.split(" ", 1)[1]
                    current_worktree["branch"] = branch_ref.replace("refs/heads/", "")

            # Handle last worktree
            if current_worktree:
                path = Path(current_worktree["worktree"])
                if path.parent.parent == base_dir and path.parent.name == project_name:
                    is_current = (
                        current_repo is not None
                        and current_repo.project_name == project_name
                    )
                    worktrees.append(
                        WorktreeInfo(
                            path=path,
                            branch=current_worktree.get("branch", "HEAD"),
                            project=project_name,
                            is_current_repo=is_current,
                        )
                    )

        except subprocess.CalledProcessError as e:
            logger.debug(
                "failed to list worktrees",
                project=project_name,
                error=str(e),
            )
            continue

    return worktrees


def complete_worktree_names(ctx, param, incomplete):
    """Provide worktree names for shell completion."""
    current_repo = None
    git_root = get_git_root()
    if git_root:
        project_name = get_project_name()
        if project_name:
            current_repo = GitRepo(root=git_root, project_name=project_name)

    worktrees = discover_worktrees(DEFAULT_WORKTREE_BASE, current_repo)
    if current_repo:
        worktrees = [wt for wt in worktrees if wt.is_current_repo]

    return [wt.path.name for wt in worktrees if wt.path.name.startswith(incomplete)]


@click.group(context_settings={"help_option_names": ["-h", "--help"]})
@click.option(
    "--global",
    "-g",
    "show_global",
    is_flag=True,
    help="Show worktrees from all projects (global scope)",
)
@click.option(
    "--log-level",
    type=click.Choice(["debug", "info", "warning", "error"], case_sensitive=False),
    default=DEFAULT_LOG_LEVEL,
    help="Set logging level",
)
@click.pass_context
def cli(ctx: click.Context, show_global: bool, log_level: str):
    """Git worktree manager for multi-project workflows."""
    # Store global flag in context for subcommands
    ctx.ensure_object(dict)
    ctx.obj["show_global"] = show_global

    # Configure structlog to output to stderr
    level = log_level.upper()
    level_int = getattr(logging, level, logging.INFO)
    structlog.configure(
        processors=[
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.dev.ConsoleRenderer(),
        ],
        wrapper_class=structlog.make_filtering_bound_logger(level_int),
        logger_factory=structlog.PrintLoggerFactory(file=sys.stderr),
    )


@cli.command()
@click.option(
    "--format",
    "-f",
    type=click.Choice(["rich", "json"], case_sensitive=False),
    default="rich",
    help="Output format",
)
@click.pass_context
def list(ctx: click.Context, format: str):
    """List git worktrees."""
    show_global = ctx.obj["show_global"]

    current_repo = None
    if not show_global:
        git_root = get_git_root()
        if git_root:
            project_name = get_project_name()
            if project_name:
                current_repo = GitRepo(
                    root=git_root,
                    project_name=project_name,
                )

    worktrees = discover_worktrees(DEFAULT_WORKTREE_BASE, current_repo)

    # Filter to current repo if needed
    if not show_global and current_repo:
        worktrees = [wt for wt in worktrees if wt.is_current_repo]

    # Create container with metadata
    worktrees_info = WorktreesInfo(
        worktrees=worktrees,
        is_global_scope=show_global,
        current_project=current_repo.project_name if current_repo else None,
    )

    if not worktrees_info.worktrees:
        if format == "json":
            # Output empty container for consistency
            print(worktrees_info.model_dump_json(indent=2))
        else:
            if current_repo:
                console.print(
                    f"[yellow]No worktrees found for project '{current_repo.project_name}'[/yellow]"
                )
            else:
                console.print("[yellow]No worktrees found[/yellow]")
        return

    format_worktrees(worktrees_info, format)
    logger.info("listed worktrees", count=worktrees_info.total_count)


@cli.command()
@click.argument("name")
def create(name: str):
    """Create a new git worktree with a new branch."""
    validate_worktree_name(name)

    # Ensure we're in a git repo
    git_root = get_git_root()
    if not git_root:
        console_err.print(
            "[red]Error: Not in a git repository. Cannot create worktree.[/red]"
        )
        sys.exit(1)

    # Get project name from git remote or fallback to directory name
    project_name = get_project_name()
    if not project_name:
        console_err.print(
            "[red]Error: Could not determine project name.[/red]"
        )
        sys.exit(1)

    repo = GitRepo(root=git_root, project_name=project_name)
    worktree_path = DEFAULT_WORKTREE_BASE / repo.project_name / name

    # Check if directory already exists
    if worktree_path.exists():
        console_err.print(
            f"[red]Error: Worktree directory already exists: {worktree_path}[/red]"
        )
        console_err.print(
            f"[yellow]Remove it first with: worktree remove {name}[/yellow]"
        )
        sys.exit(1)

    # Create parent directory if needed
    worktree_path.parent.mkdir(parents=True, exist_ok=True)

    # Create worktree with new branch
    try:
        logger.debug(
            "creating worktree",
            name=name,
            path=str(worktree_path),
            project=repo.project_name,
        )

        subprocess.run(
            ["git", "worktree", "add", "-b", name, str(worktree_path), "HEAD"],
            cwd=repo.root,
            check=True,
            capture_output=True,
            text=True,
        )

        console.print(f"[green]✓ Created worktree: {worktree_path}[/green]")
        logger.info(
            "created worktree",
            name=name,
            path=str(worktree_path),
            branch=name,
            project=repo.project_name,
        )

    except subprocess.CalledProcessError as e:
        console_err.print(f"[red]Error creating worktree: {e.stderr}[/red]")
        sys.exit(1)


@cli.command()
@click.argument("name", shell_complete=complete_worktree_names)
def remove(name: str):
    """Remove a git worktree (keeps the branch)."""
    validate_worktree_name(name)

    # Ensure we're in a git repo
    git_root = get_git_root()
    if not git_root:
        console_err.print(
            "[red]Error: Not in a git repository. Cannot remove worktree.[/red]"
        )
        sys.exit(1)

    # Get project name from git remote or fallback to directory name
    project_name = get_project_name()
    if not project_name:
        console_err.print(
            "[red]Error: Could not determine project name.[/red]"
        )
        sys.exit(1)

    repo = GitRepo(root=git_root, project_name=project_name)
    worktree_path = DEFAULT_WORKTREE_BASE / repo.project_name / name

    try:
        logger.debug(
            "removing worktree",
            name=name,
            path=str(worktree_path),
            project=repo.project_name,
        )

        subprocess.run(
            ["git", "worktree", "remove", str(worktree_path)],
            cwd=repo.root,
            check=True,
            capture_output=True,
            text=True,
        )

        console.print(f"[green]✓ Removed worktree: {worktree_path}[/green]")
        console.print(f"[yellow]Branch '{name}' was kept (not deleted)[/yellow]")
        logger.info(
            "removed worktree",
            name=name,
            path=str(worktree_path),
            project=repo.project_name,
        )

    except subprocess.CalledProcessError as e:
        console_err.print(f"[red]Error removing worktree: {e.stderr}[/red]")
        sys.exit(1)


if __name__ == "__main__":
    cli()
