#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["click", "rich", "pydantic"]
# ///

"""
Upstream issue tracker for codebase workarounds.

Scans code for @upstream-issue tags, checks GitHub issue status via gh CLI,
and reports which workarounds can be removed.
"""

import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

import click
from click.shell_completion import ZshComplete, add_completion_class
from pydantic import BaseModel
from rich.console import Console


# Custom ZshComplete that generates function names compatible with zsh autoload
@add_completion_class
class AutoloadZshComplete(ZshComplete):
    """ZshComplete subclass that generates function names matching filename convention.

    This enables zsh autoload from fpath by ensuring the function name
    (_check_upstream_issues) matches the completion filename, rather than
    Click's default (_check_upstream_issues_completion).
    """

    name = "zsh"

    @property
    def func_name(self) -> str:
        """Generate function name without _completion suffix for zsh autoload."""
        safe_name = re.sub(r"\W+", "", self.prog_name.replace("-", "_"), flags=re.ASCII)
        return f"_{safe_name}"


# Global console
console = Console()
console_err = Console(file=sys.stderr, stderr=True)


class IssueLocation(BaseModel):
    """Location of an @upstream-issue tag in the codebase."""

    file: Path
    line: int
    comment: str


class IssueStatus(BaseModel):
    """Status of a GitHub issue with its locations in the codebase."""

    url: str
    org: str
    repo: str
    number: int
    state: str  # "open" or "closed"
    closed_at: Optional[str]
    title: str
    locations: list[IssueLocation]


class Summary(BaseModel):
    """Summary statistics for issue tracking."""

    resolved_count: int
    open_count: int


class OutputReport(BaseModel):
    """Complete output report for issue tracking."""

    resolved: list[IssueStatus]
    open: list[IssueStatus]
    summary: Summary


def find_upstream_issues(
    directory: Path, default_repo: Optional[str]
) -> dict[str, list[IssueLocation]]:
    """Use ripgrep to find @upstream-issue tags.

    Args:
        directory: Directory to scan
        default_repo: Default repository for #123 shorthand (format: "org/repo")

    Returns:
        Dictionary mapping issue URLs to their locations
    """
    # Run ripgrep to find all @upstream-issue tags
    result = subprocess.run(
        [
            "rg",
            "--line-number",
            "--no-heading",
            "--no-follow",  # Don't follow symlinks
            "--glob",
            "!check-upstream-issues.py",  # Exclude this script (has example tags)
            r"@upstream-issue:\s*(?:https://github\.com/[^/]+/[^/]+/issues/\d+|#\d+)",
        ],
        cwd=directory,
        capture_output=True,
        text=True,
    )

    # ripgrep exit codes:
    # 0 = matches found
    # 1 = no matches
    # 2 = error occurred (e.g., broken symlink) but partial results may be valid
    # We accept codes 0-2 since ripgrep still produces usable results
    # Stderr warnings (like broken symlinks) are expected and can be ignored
    if result.returncode > 2:
        # Only fail for truly fatal errors (code > 2)
        console_err.print(
            f"[red]Fatal error running ripgrep (exit {result.returncode}):[/red]"
        )
        if result.stderr:
            console_err.print(result.stderr)
        sys.exit(1)

    # Parse ripgrep output: file:line:matched_text
    issues: dict[str, list[IssueLocation]] = {}
    url_pattern = re.compile(
        r"@upstream-issue:\s*(?:https://github\.com/([^/]+)/([^/]+)/issues/(\d+)|#(\d+))"
    )

    for line in result.stdout.splitlines():
        if not line.strip():
            continue

        # Split on first two colons to get file:line:content
        parts = line.split(":", 2)
        if len(parts) < 3:
            continue

        file_path = Path(parts[0])
        line_num = int(parts[1])
        content = parts[2]

        # Extract issue URL or shorthand
        match = url_pattern.search(content)
        if not match:
            continue

        if match.group(4):  # Shorthand format (#123)
            if not default_repo:
                console_err.print(
                    f"[yellow]Warning:[/yellow] Found shorthand issue #{match.group(4)} "
                    f"at {file_path}:{line_num} but no --repo specified. Skipping."
                )
                continue
            org, repo = default_repo.split("/")
            number = match.group(4)
            url = f"https://github.com/{org}/{repo}/issues/{number}"
        else:  # Full URL format
            org = match.group(1)
            repo = match.group(2)
            number = match.group(3)
            url = f"https://github.com/{org}/{repo}/issues/{number}"

        location = IssueLocation(file=file_path, line=line_num, comment=content.strip())

        if url not in issues:
            issues[url] = []
        issues[url].append(location)

    return issues


def check_issue_status(org: str, repo: str, number: int) -> dict:
    """Check GitHub issue status using gh CLI.

    Args:
        org: GitHub organization
        repo: Repository name
        number: Issue number

    Returns:
        Issue data from GitHub API
    """
    try:
        result = subprocess.run(
            ["gh", "api", f"/repos/{org}/{repo}/issues/{number}"],
            capture_output=True,
            text=True,
            check=True,
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        console_err.print(
            f"[red]Error checking {org}/{repo}#{number}:[/red] {e.stderr}"
        )
        return {}
    except json.JSONDecodeError as e:
        console_err.print(f"[red]Error parsing GitHub API response:[/red] {e}")
        return {}


def parse_url(url: str) -> tuple[str, str, int]:
    """Parse GitHub issue URL into org, repo, number.

    Args:
        url: GitHub issue URL

    Returns:
        Tuple of (org, repo, number)
    """
    pattern = re.compile(r"https://github\.com/([^/]+)/([^/]+)/issues/(\d+)")
    match = pattern.match(url)
    if not match:
        raise ValueError(f"Invalid GitHub issue URL: {url}")
    return match.group(1), match.group(2), int(match.group(3))


def format_time_ago(closed_at: Optional[str]) -> str:
    """Format closed_at timestamp as human-readable time ago.

    Args:
        closed_at: ISO 8601 timestamp string

    Returns:
        Human-readable string like "2 months ago"
    """
    if not closed_at:
        return "unknown"

    try:
        closed_time = datetime.fromisoformat(closed_at.replace("Z", "+00:00"))
        now = datetime.now(closed_time.tzinfo)
        delta = now - closed_time

        days = delta.days
        if days == 0:
            hours = delta.seconds // 3600
            if hours == 0:
                return "less than an hour ago"
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        elif days == 1:
            return "1 day ago"
        elif days < 30:
            return f"{days} days ago"
        elif days < 60:
            return "1 month ago"
        elif days < 365:
            months = days // 30
            return f"{months} months ago"
        else:
            years = days // 365
            return f"{years} year{'s' if years != 1 else ''} ago"
    except (ValueError, AttributeError):
        return "unknown"


def format_rich_output(resolved: list[IssueStatus], open_issues: list[IssueStatus]):
    """Format output using Rich for terminal display.

    Args:
        resolved: List of resolved (closed) issues
        open_issues: List of still-open issues
    """
    if resolved:
        console.print("\n[bold green]RESOLVED (can be removed):[/bold green]")
        for issue in resolved:
            time_ago = format_time_ago(issue.closed_at)
            console.print(
                f"  [green]✓[/green] {issue.org}/{issue.repo}#{issue.number} - "
                f"CLOSED {time_ago}"
            )
            console.print(f"    [dim]{issue.title}[/dim]")
            for loc in issue.locations:
                console.print(f"    {loc.file}:{loc.line}")
                console.print(f"    [dim]{loc.comment}[/dim]")
            console.print()

    if open_issues:
        console.print("[bold yellow]STILL OPEN (keep workaround):[/bold yellow]")
        for issue in open_issues:
            console.print(
                f"  [yellow]○[/yellow] {issue.org}/{issue.repo}#{issue.number} - OPEN"
            )
            console.print(f"    [dim]{issue.title}[/dim]")
            for loc in issue.locations:
                console.print(f"    {loc.file}:{loc.line}")
                console.print(f"    [dim]{loc.comment}[/dim]")
            console.print()

    # Summary
    total = len(resolved) + len(open_issues)
    if total > 0:
        console.print(
            f"[bold]Summary:[/bold] {len(resolved)} resolved, {len(open_issues)} still open"
        )
    else:
        console.print("[dim]No @upstream-issue tags found.[/dim]")


def format_json_output(resolved: list[IssueStatus], open_issues: list[IssueStatus]):
    """Format output as JSON for scripting.

    Args:
        resolved: List of resolved (closed) issues
        open_issues: List of still-open issues
    """
    output = OutputReport(
        resolved=resolved,
        open=open_issues,
        summary=Summary(
            resolved_count=len(resolved),
            open_count=len(open_issues),
        ),
    )
    print(output.model_dump_json(indent=2))


@click.command()
@click.argument("directory", type=click.Path(exists=True), default=".")
@click.option(
    "--closed-only",
    is_flag=True,
    help="Only show resolved issues (exit code 2 if any found)",
)
@click.option("--json", "output_json", is_flag=True, help="Output as JSON")
@click.option(
    "--repo",
    help="Default repository for #123 shorthand (format: org/repo)",
)
def main(directory, closed_only, output_json, repo):
    """Check status of upstream issues tracked in codebase.

    Scans DIRECTORY for @upstream-issue tags and checks their GitHub status.

    Tag format:
      # @upstream-issue: https://github.com/org/repo/issues/123
      # @upstream-issue: #456  (requires --repo flag)
    """
    dir_path = Path(directory).resolve()

    if not output_json:
        console.print(f"Checking for upstream issues in {dir_path}...\n")

    # Find all @upstream-issue tags
    issue_locations = find_upstream_issues(dir_path, repo)

    if not issue_locations:
        if not output_json:
            console.print("[dim]No @upstream-issue tags found.[/dim]")
        sys.exit(0)

    if not output_json:
        console.print(f"Found {len(issue_locations)} tracked upstream issue(s):\n")

    # Check status of each issue
    resolved = []
    open_issues = []

    for url, locations in issue_locations.items():
        org, repo_name, number = parse_url(url)
        api_data = check_issue_status(org, repo_name, number)

        if not api_data:
            continue

        issue = IssueStatus(
            url=url,
            org=org,
            repo=repo_name,
            number=number,
            state=api_data.get("state", "unknown"),
            closed_at=api_data.get("closed_at"),
            title=api_data.get("title", ""),
            locations=locations,
        )

        if issue.state == "closed":
            resolved.append(issue)
        else:
            open_issues.append(issue)

    # Output results
    if output_json:
        format_json_output(resolved, open_issues)
    else:
        format_rich_output(resolved, open_issues)

    # Exit codes
    if closed_only and resolved:
        sys.exit(2)  # Resolved issues found
    elif not resolved and not open_issues:
        sys.exit(1)  # Errors occurred
    else:
        sys.exit(0)  # Success


if __name__ == "__main__":
    main()
