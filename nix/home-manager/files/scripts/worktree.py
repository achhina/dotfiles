#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["click", "structlog", "rich", "pydantic"]
# ///

"""
Git worktree manager for multi-project workflows.

Manages git worktrees in a centralized directory structure:
~/worktrees/<project>/<worktree-name>/
"""

import glob
import logging
import subprocess
import sys
from fnmatch import fnmatch
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
console_err = Console(file=sys.stderr, stderr=True)
logger = structlog.get_logger()


class Worktree(BaseModel):
    """Represents a git worktree with its metadata."""

    model_config = ConfigDict(frozen=True)

    path: Path
    branch: str


class Project(BaseModel):
    """Represents a project with its worktrees."""

    model_config = ConfigDict(frozen=True)

    name: str
    main_repo_path: Path
    remote_origin_url: Optional[str]
    worktrees: list[Worktree]


class GitRepo(BaseModel):
    """Represents the current git repository context."""

    model_config = ConfigDict(frozen=True)

    root: Path
    project_name: str


def format_projects(projects: list[Project], format: str) -> None:
    """Format and display projects and their worktrees in the specified format."""
    if format == "json":
        # Serialize projects directly
        import json
        print(json.dumps([p.model_dump(mode='json') for p in projects], indent=2, default=str))
    elif format == "rich":
        # Create rich table
        table = Table(title="Git Worktrees")
        table.add_column("Project", style="cyan")
        table.add_column("Branch", style="green")
        table.add_column("Path", style="blue")

        for project in projects:
            for wt in project.worktrees:
                table.add_row(project.name, wt.branch, str(wt.path))

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


def discover_projects(base_dir: Path) -> list[Project]:
    """Scan ~/worktrees/ and parse 'git worktree list' for each project."""
    projects = []

    if not base_dir.exists():
        return projects

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

        # Get remote origin URL
        remote_origin_url = None
        try:
            result = subprocess.run(
                ["git", "config", "--get", "remote.origin.url"],
                cwd=main_repo,
                capture_output=True,
                text=True,
                check=True,
            )
            remote_origin_url = result.stdout.strip() or None
        except subprocess.CalledProcessError:
            pass

        # Get worktree list from git
        worktrees = []
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
                            worktrees.append(
                                Worktree(
                                    path=path,
                                    branch=current_worktree.get("branch", "HEAD"),
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
                    worktrees.append(
                        Worktree(
                            path=path,
                            branch=current_worktree.get("branch", "HEAD"),
                        )
                    )

            if worktrees:
                projects.append(
                    Project(
                        name=project_name,
                        main_repo_path=main_repo,
                        remote_origin_url=remote_origin_url,
                        worktrees=worktrees,
                    )
                )

        except subprocess.CalledProcessError as e:
            logger.debug(
                "failed to list worktrees",
                project=project_name,
                error=str(e),
            )
            continue

    return projects


def complete_worktree_names(ctx, param, incomplete):
    """Provide worktree names for shell completion with glob pattern support."""
    projects = discover_projects(DEFAULT_WORKTREE_BASE)

    # Filter to current project if in a git repo
    current_project_name = get_project_name()
    if current_project_name:
        projects = [p for p in projects if p.name == current_project_name]

    # Flatten worktrees from all matching projects
    worktree_names = []
    has_glob = any(c in incomplete for c in ['*', '?', '['])

    for project in projects:
        for wt in project.worktrees:
            name = wt.path.name
            # Use glob matching if pattern contains wildcards, otherwise prefix match
            if has_glob:
                if fnmatch(name, incomplete):
                    worktree_names.append(name)
            else:
                if name.startswith(incomplete):
                    worktree_names.append(name)

    return worktree_names


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

    projects = discover_projects(DEFAULT_WORKTREE_BASE)

    # Filter to current project if not showing global
    current_project_name = None
    if not show_global:
        current_project_name = get_project_name()
        if current_project_name:
            projects = [p for p in projects if p.name == current_project_name]

    if not projects:
        if format == "json":
            # Output empty list for consistency
            print("[]")
        else:
            if current_project_name:
                console.print(
                    f"[yellow]No worktrees found for project '{current_project_name}'[/yellow]"
                )
            else:
                console.print("[yellow]No worktrees found[/yellow]")
        return

    format_projects(projects, format)

    # Count total worktrees across all projects
    total_worktrees = sum(len(p.worktrees) for p in projects)
    logger.info("listed worktrees", count=total_worktrees, projects=len(projects))


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
            f"[yellow]Worktree already exists: {worktree_path}[/yellow]"
        )
        # Print path to stdout so shell wrapper can cd to it
        print(str(worktree_path))
        sys.exit(0)

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

        console_err.print(f"[green]✓ Created worktree: {worktree_path}[/green]")
        logger.info(
            "created worktree",
            name=name,
            path=str(worktree_path),
            branch=name,
            project=repo.project_name,
        )

        # Print path to stdout for shell wrapper consumption
        print(str(worktree_path))

    except subprocess.CalledProcessError as e:
        console_err.print(f"[red]Error creating worktree: {e.stderr}[/red]")
        sys.exit(1)


@cli.command()
@click.argument("names", nargs=-1, required=True, shell_complete=complete_worktree_names)
@click.option(
    "--delete-branch",
    "-d",
    is_flag=True,
    help="Also delete the git branch when removing the worktree",
)
def remove(names: tuple[str, ...], delete_branch: bool):
    """Remove one or more git worktrees (keeps the branches by default).

    Supports glob patterns: worktree remove 'test*' 'feature-*'
    """
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

    # Expand glob patterns to actual worktree names using glob.glob
    project_worktree_dir = DEFAULT_WORKTREE_BASE / repo.project_name

    expanded_names = []
    for pattern in names:
        # Check if pattern contains glob characters
        if any(c in pattern for c in ['*', '?', '[']):
            # Use glob.glob to expand the pattern against actual directories
            matches = glob.glob(str(project_worktree_dir / pattern))
            if not matches:
                console_err.print(f"[yellow]Warning: No worktrees match pattern '{pattern}'[/yellow]")
            # Extract just the worktree names from full paths
            expanded_names.extend([Path(m).name for m in matches])
        else:
            # Literal name
            expanded_names.append(pattern)

    if not expanded_names:
        console_err.print("[red]Error: No worktrees to remove[/red]")
        sys.exit(1)

    failed = []
    succeeded = []
    branches_deleted = []

    for name in expanded_names:
        # Validate each name
        try:
            validate_worktree_name(name)
        except click.BadParameter as e:
            console_err.print(f"[red]✗ {name}: {e.format_message()}[/red]")
            failed.append(name)
            continue

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

            console_err.print(f"[green]✓ Removed worktree: {worktree_path}[/green]")
            logger.info(
                "removed worktree",
                name=name,
                path=str(worktree_path),
                project=repo.project_name,
            )
            succeeded.append(name)

            # Delete branch if requested
            if delete_branch:
                try:
                    subprocess.run(
                        ["git", "branch", "-D", name],
                        cwd=repo.root,
                        check=True,
                        capture_output=True,
                        text=True,
                    )
                    console_err.print(f"[green]✓ Deleted branch: {name}[/green]")
                    logger.info(
                        "deleted branch",
                        branch=name,
                        project=repo.project_name,
                    )
                    branches_deleted.append(name)
                except subprocess.CalledProcessError as e:
                    console_err.print(f"[yellow]⚠ Could not delete branch {name}: {e.stderr.strip()}[/yellow]")

        except subprocess.CalledProcessError as e:
            console_err.print(f"[red]✗ Error removing {name}: {e.stderr.strip()}[/red]")
            failed.append(name)

    # Print summary if multiple worktrees
    if len(names) > 1:
        console_err.print()
        if succeeded:
            console_err.print(f"[green]Successfully removed {len(succeeded)} worktree(s)[/green]")
            if delete_branch:
                if branches_deleted:
                    console_err.print(f"[green]Deleted {len(branches_deleted)} branch(es)[/green]")
            else:
                console_err.print(f"[yellow]Branches were kept (not deleted)[/yellow]")
        if failed:
            console_err.print(f"[red]Failed to remove {len(failed)} worktree(s)[/red]")

    # Exit with error if any failed
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    cli()
