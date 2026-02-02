# Command Line Recipes

Useful command combinations and workflows for this dotfiles repository.

## Analyzing Command Usage

### Extract unique commands from Claude Code sessions and shell history

Combine Claude Code tool calls with your shell history to see what commands you actually use:

```bash
parse-claude-tools --current --today --json | \
  jq -r '.Bash[].input.command' | \
  parse-history --include-history --json 2>/dev/null | \
  jq -r 'to_entries[] | .value[]' | \
  grep '^[a-z][a-z-]* [a-z][a-z-]*' | \
  sort -u
```

**What it does:**

1. Extracts all Bash commands Claude executed in today's sessions for the current project
2. Pipes those commands into the shell history parser
3. Combines with your actual zsh/bash history files
4. Filters to clean command+subcommand pairs (e.g., "git add", "npm install")
5. Outputs unique entries, one per line

**Useful variants:**

```bash
# All projects, last week
parse-claude-tools --last-week --json | \
  jq -r '.Bash[].input.command' | \
  parse-history --json 2>/dev/null | \
  jq -r 'to_entries[] | .value[]' | \
  grep '^[a-z][a-z-]* [a-z][a-z-]*' | \
  sort -u

# Only shell history, no Claude sessions
parse-history --json | \
  jq -r 'to_entries[] | .value[]' | \
  grep '^[a-z][a-z-]* [a-z][a-z-]*' | \
  sort -u

# Count command frequency
parse-claude-tools --current --today --json | \
  jq -r '.Bash[].input.command' | \
  parse-history --include-history --json 2>/dev/null | \
  jq -r 'to_entries[] | .value[]' | \
  grep '^[a-z][a-z-]* [a-z][a-z-]*' | \
  sort | uniq -c | sort -rn
```

### View all Claude Code tool calls for today

```bash
parse-claude-tools --current --today
```

### View specific tool usage with full arguments

```bash
# See all Read tool calls with file paths
parse-claude-tools --current --today --json | \
  jq '.Read[]'

# See all Edit operations
parse-claude-tools --current --today --json | \
  jq '.Edit[]'
```

### Analyze shell history without Claude sessions

```bash
# Categorized output with colors
parse-history

# JSON output for further processing
parse-history --json

# Only from specific file
parse-history --file ~/.bash_history --shell-type bash
```

## Working with these recipes

Both `parse-history` and `parse-claude-tools` are declaratively managed scripts deployed via Home Manager. Source files are located in:

- `~/.config/nix/home-manager/files/scripts/parse-history`
- `~/.config/nix/home-manager/files/scripts/parse-claude-tools`

After editing either script, run `hm switch` to deploy changes.
