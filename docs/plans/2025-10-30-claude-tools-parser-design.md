# Claude Code Tool Call Parser Design

## Purpose

Extract and display tool calls with their arguments from Claude Code session transcripts. Parse JSONL files to show what tools Claude executed during conversations.

## Requirements

- Parse session JSONL files from `~/.claude/projects/`
- Extract tool_use messages with full input arguments
- Support project and time-based filtering
- Display categorized by tool name with timestamps
- Provide JSON output option
- Use claude-code-log for robust parsing

## Implementation

### Dependencies

The script uses PEP 723 inline metadata with three dependencies:

- **claude-code-log**: Parses JSONL transcripts with Pydantic validation
- **click**: Provides CLI argument parsing
- **rich**: Handles terminal color output

When invoked with `uv run parse-claude-tools`, uv creates an isolated environment and installs dependencies automatically.

### Architecture

```
1. Locate session JSONL files in ~/.claude/projects/
2. Filter by project, session ID, or time range
3. For each file:
   a. Parse with claude-code-log
   b. Extract tool_use content items
   c. Collect tool name, timestamp, and input
4. Store in dict: {tool_name: [tool_calls]}
5. Output categorized with color or JSON
```

### Session Discovery

**File Location**: `~/.claude/projects/<project-slug>/<session-uuid>.jsonl`

**Project Slug Format**: Path with slashes replaced by hyphens
- `/Users/achhina/.config` becomes `-Users-achhina--config`

**Discovery Logic**:
```python
def find_session_files(project_filter=None):
    projects_dir = Path.home() / '.claude' / 'projects'

    if project_filter:
        project_dir = projects_dir / project_filter
        return list(project_dir.glob('*.jsonl'))

    # All projects
    return [f for p in projects_dir.iterdir()
            if p.is_dir() for f in p.glob('*.jsonl')]
```

**Current Project Detection**:
```python
def get_current_project():
    cwd = Path.cwd()
    return str(cwd).replace('/', '-')
```

### Tool Call Extraction

**Using claude-code-log Parser**:
```python
from claude_code_log.parser import parse_session_file

def extract_tool_calls(session_path):
    messages = parse_session_file(session_path)

    tool_calls = []
    for msg in messages:
        if hasattr(msg, 'content'):
            for item in msg.content:
                if item.type == 'tool_use':
                    tool_calls.append({
                        'timestamp': msg.timestamp,
                        'tool': item.name,
                        'input': item.input
                    })

    return tool_calls
```

**Benefits of claude-code-log**:
- Pydantic models ensure type safety
- Handles malformed JSONL gracefully
- Supports all message types correctly
- Validates data structure automatically

### CLI Options

```bash
# All projects
parse-claude-tools

# Current project only
parse-claude-tools --current

# Specific project
parse-claude-tools --project -Users-achhina--config

# Specific session
parse-claude-tools --session 19362f2f-208d-4860-993f-16db816a71bb

# Time filters
parse-claude-tools --today
parse-claude-tools --yesterday
parse-claude-tools --last-week

# JSON output
parse-claude-tools --json
```

### Output Formats

**Terminal (default)**:
```
Bash (127 calls)
  [2025-10-30 22:10:34] ls -la ~/.claude/projects/-Users-achhina--config/
  [2025-10-30 22:08:15] git status
  [2025-10-30 22:05:42] parse-history 2>&1 | head -50

Read (45 calls)
  [2025-10-30 21:57:12] /Users/achhina/.config/nix/home-manager/modules/shell.nix
  [2025-10-30 21:55:30] /Users/achhina/.config/nix/home-manager/files/scripts/parse-history

Edit (12 calls)
  [2025-10-30 21:58:45] /Users/achhina/.config/nix/home-manager/files/scripts/parse-history
    old_string: "#!/usr/bin/env -S uv run"
    new_string: "#!/usr/bin/env -S uv run --script"
```

Tool names appear in bold cyan. Timestamps appear dimmed. Long arguments truncate with ellipsis.

**JSON** (with `--json` flag):
```json
{
  "Bash": [
    {
      "timestamp": "2025-10-30T22:10:34.763Z",
      "input": {
        "command": "ls -la ~/.claude/projects/-Users-achhina--config/",
        "description": "Check current project's sessions"
      }
    }
  ],
  "Read": [
    {
      "timestamp": "2025-10-30T21:57:12.000Z",
      "input": {
        "file_path": "/Users/achhina/.config/nix/home-manager/modules/shell.nix"
      }
    }
  ]
}
```

### Error Handling

**Session Processing**:
```python
def process_all_sessions(session_files):
    all_tool_calls = {}
    errors = []

    for session_file in session_files:
        try:
            tool_calls = extract_tool_calls(session_file)
            merge_tool_calls(all_tool_calls, tool_calls)
        except Exception as e:
            errors.append(f"Error in {session_file.name}: {e}")

    if errors:
        for error in errors:
            err_console.print(f"[dim red]{error}[/dim red]")

    return all_tool_calls
```

**Error Scenarios**:
- Malformed JSON lines: Skip with warning to stderr
- Missing projects directory: Exit with error message
- Empty session files: Return empty results
- No matching sessions: Print helpful message

### Deployment

**Source Location**: `~/.config/nix/home-manager/files/scripts/parse-claude-tools`

**Deployed Location**: `~/bin/parse-claude-tools`

**Home Manager Configuration**:
```nix
home.file."bin/parse-claude-tools" = {
  source = ../files/scripts/parse-claude-tools;
  executable = true;
};
```

Run `hm switch` to deploy after creation.

## Trade-offs

- Uses claude-code-log library (adds dependency but ensures correctness)
- No frequency statistics (keeps output simple)
- No result content display (focuses on what Claude tried to do, not results)
- Processes all sessions by default (can be slow but comprehensive)
