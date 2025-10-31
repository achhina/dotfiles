# Shell History Parser Design

## Purpose

Parse shell history files to extract commands and subcommands. Display results categorized by base command with color output or JSON format.

## Requirements

- Auto-detect `~/.zsh_history` and `~/.bash_history`
- Extract all commands from complex constructs (pipes, substitutions, etc.)
- Extract subcommands (first non-flag argument only)
- Output categorized by base command
- Support JSON output flag
- Use color when outputting to terminal
- Log errors to stderr

## Implementation

### Dependencies

The script uses PEP 723 inline metadata with three dependencies:

- **bashlex**: Parses shell commands into AST
- **click**: Provides CLI argument parsing
- **rich**: Handles terminal color output

When invoked with `uv run parse-history`, uv creates an isolated environment and installs dependencies automatically.

### Architecture

```
1. Auto-detect history files
2. For each file:
   a. Read line by line
   b. Clean shell-specific metadata
   c. Parse with bashlex to get AST
   d. Walk AST to extract commands
3. Store in dict: {base_cmd: {subcommands}}
4. Output categorized with color or JSON
```

### History File Formats

**Bash** (`~/.bash_history`):
- Newline-delimited commands
- Read directly, no preprocessing

**Zsh** (`~/.zsh_history`):
- Extended format: `: <timestamp>:<duration>;<command>`
- Contains escape sequences
- Strip metadata before parsing

```python
def extract_command_from_line(line, shell_type):
    if shell_type == 'zsh':
        if line.startswith(':'):
            line = line.split(';', 1)[1] if ';' in line else line
        line = line.encode().decode('unicode_escape')
    return line.strip()
```

### Command Extraction

bashlex creates an AST for each command. Walk the tree to find command nodes and extract:

1. **Base command**: The executable name
2. **Subcommand**: First argument that doesn't start with `-`

```python
def extract_commands(node, commands_dict):
    if node.kind == 'command':
        parts = [n.word for n in node.parts if hasattr(n, 'word')]
        if parts:
            base_cmd = parts[0]
            if base_cmd not in commands_dict:
                commands_dict[base_cmd] = set()

            # Find first non-flag argument
            if len(parts) > 1:
                for arg in parts[1:]:
                    if not arg.startswith('-'):
                        commands_dict[base_cmd].add(f"{base_cmd} {arg}")
                        break

    # Recurse for pipes, &&, ||, etc.
    if hasattr(node, 'parts'):
        for part in node.parts:
            extract_commands(part, commands_dict)
```

### Output Formats

**Terminal (default)**:
```
docker
  docker build
  docker ps
  docker run

git
  git add
  git commit
```

Base commands appear in bold cyan. Rich detects TTY automatically and disables color when piping.

**JSON** (with `--json` flag):
```json
{
  "docker": ["docker build", "docker ps", "docker run"],
  "git": ["git add", "git commit"]
}
```

### Error Handling

- Skip unparseable lines silently (malformed commands, partial edits)
- Log unexpected errors to stderr with file location
- Exit with error if no history files exist
- Handle encoding issues with `errors='ignore'`

### Deployment

**Location**: `~/.config/nix/home-manager/files/scripts/parse-history`

**Deployed to**: `~/bin/parse-history`

**Managed via**: Home Manager `shell.nix` configuration

```nix
home.file."bin/parse-history" = {
  source = ../files/scripts/parse-history;
  executable = true;
};
```

Run `hm switch` to deploy after creation.

## Trade-offs

- No frequency counts (keeps code simple)
- No command filtering (user can pipe to `grep`)
- Cannot resolve aliases (would require shell-specific lookup)
- bashlex handles edge cases at cost of one dependency
