{
  pkgs,
  lib,
  ...
}:

let
  # Software development detector hook script (general principles for any git repo)
  softwareDevelopmentDetector = pkgs.writeShellScript "software-development-detector.sh" (builtins.readFile ./hooks/software-development-detector.sh);

  # Python project detector hook script (Python-specific practices)
  pythonProjectDetector = pkgs.writeShellScript "python-project-detector.sh" (builtins.readFile ./hooks/python-project-detector.sh);
in
{
  # Claude Code settings configuration
  # Managed declaratively through Home Manager

  programs.claude-code = {
    enable = true;
    package = null; # Don't install claude-code via Nix, use npm install instead

    commandsDir = ./slash-commands;

    # User-level memory (personal preferences across all projects)
    # AGENTS.md is the source file, deployed as CLAUDE.md for Claude Code
    memory.source = ./context/AGENTS.md;

    # Skills directory - all skills symlinked from ./skills/
    skillsDir = ./skills;

    # Agents directory - custom subagents
    agentsDir = ./agents;

    settings = {
      env = {
        BASH_DEFAULT_TIMEOUT_MS = "300000";
        BASH_MAX_TIMEOUT_MS = "600000";
      };

      includeCoAuthoredBy = false;

      permissions = {
        allow = [
          "Bash(awk:*)"
          "Bash(cat:*)"
          "Bash(command:*)"
          "Bash(col:*)"
          "Bash(diff:*)"
          "Bash(echo:*)"
          "Bash(find:*)"
          "Bash(fd:*)"
          "Bash(git add:*)"
          "Bash(git commit:*)"
          "Bash(git log:*)"
          "Bash(git ls-tree:*)"
          "Bash(git worktree:*)"
          "Bash(gh attestation verify:*)"
          "Bash(gh auth status:*)"
          "Bash(gh browse:*)"
          "Bash(gh cache list:*)"
          "Bash(gh config get:*)"
          "Bash(gh copilot:*)"
          "Bash(gh gist list:*)"
          "Bash(gh gpg-key list:*)"
          "Bash(gh issue list:*)"
          "Bash(gh issue view:*)"
          "Bash(gh label list:*)"
          "Bash(gh pr checks:*)"
          "Bash(gh pr diff:*)"
          "Bash(gh pr list:*)"
          "Bash(gh pr view:*)"
          "Bash(gh release list:*)"
          "Bash(gh release view:*)"
          "Bash(gh repo view:*)"
          "Bash(gh run list:*)"
          "Bash(gh run view:*)"
          "Bash(gh search:*)"
          "Bash(gh ssh-key list:*)"
          "Bash(gh status:*)"
          "Bash(gh workflow list:*)"
          "Bash(gh workflow view:*)"
          "Bash(grep:*)"
          "Bash(head:*)"
          "Bash(hm:*)"
          "Bash(home-manager:*)"
          "Bash(jest:*)"
          "Bash(just:*)"
          "Bash(ls:*)"
          "Bash(lsof:*)"
          "Bash(man:*)"
          "Bash(mkdir:*)"
          "Bash(mypy:*)"
          "Bash(nix:*)"
          "Bash(nix-channel:*)"
          "Bash(nix-shell:*)"
          "Bash(nix-collect-garbage:*)"
          "Bash(npm:*)"
          "Bash(nvim:*)"
          "Bash(playwright:*)"
          "Bash(pre-commit:*)"
          "Bash(pytest:*)"
          "Bash(python:*)"
          "Bash(rg:*)"
          "Bash(ruff:*)"
          "Bash(sed:*)"
          "Bash(sort:*)"
          "Bash(tail:*)"
          "Bash(test:*)"
          "Bash(timeout:*)"
          "Bash(tmux list-:*)"
          "Bash(tmux show-:*)"
          "Bash(tmux display:*)"
          "Bash(tmux has-session:*)"
          "Bash(tmux capture-pane:*)"
          "Bash(tree:*)"
          "Bash(ty:*)"
          "Bash(unzip:*)"
          "Bash(uv:*)"
          "Bash(worktree:*)"
          "Bash(yarn:*)"
          "Bash(zip:*)"
          "Bash(/usr/bin/man:*)"
          "Bash(~/bin/man:*)"
          # Docker read-only commands
          "Bash(docker ps:*)"
          "Bash(docker images:*)"
          "Bash(docker version:*)"
          "Bash(docker info:*)"
          "Bash(docker search:*)"
          "Bash(docker inspect:*)"
          "Bash(docker logs:*)"
          "Bash(docker diff:*)"
          "Bash(docker events:*)"
          "Bash(docker history:*)"
          "Bash(docker port:*)"
          "Bash(docker stats:*)"
          "Bash(docker top:*)"
          "Bash(docker manifest inspect:*)"
          # Docker management commands (read-only)
          "Bash(docker container ls:*)"
          "Bash(docker container inspect:*)"
          "Bash(docker container logs:*)"
          "Bash(docker container stats:*)"
          "Bash(docker container top:*)"
          "Bash(docker container port:*)"
          "Bash(docker image ls:*)"
          "Bash(docker image inspect:*)"
          "Bash(docker image history:*)"
          "Bash(docker network ls:*)"
          "Bash(docker network inspect:*)"
          "Bash(docker volume ls:*)"
          "Bash(docker volume inspect:*)"
          "Bash(docker system df:*)"
          "Bash(docker system info:*)"
          "Bash(docker system events:*)"
          # Homebrew read-only commands
          "Bash(brew search:*)"
          "Bash(brew info:*)"
          "Bash(brew list:*)"
          "Bash(brew config:*)"
          "Bash(brew doctor:*)"
          "Bash(brew outdated:*)"
          "Bash(brew deps:*)"
          "Bash(brew uses:*)"
          "Bash(brew commands:*)"
          "Bash(brew help:*)"
          "Bash(brew --version:*)"
          "Bash(brew --prefix:*)"
          "Bash(brew --cellar:*)"
          "Bash(brew --repository:*)"
          "Bash(brew tap-info:*)"
          "Bash(brew leaves:*)"
          "Bash(brew desc:*)"
          # Git read-only commands
          "Bash(git show:*)"
          "Bash(git blame:*)"
          "Bash(git branch:*)"
          "Bash(git diff:*)"
          "Bash(git remote:*)"
          "Bash(git config --get:*)"
          "Bash(git config --list:*)"
          # GitHub CLI read-only API calls
          "Bash(gh api --method GET:*)"
          "Bash(gh api --method=GET:*)"
          "Bash(gh api -X GET:*)"
          "Bash(gh api -XGET:*)"
          # System information commands
          "Bash(which:*)"
          "Bash(whence:*)"
          "Bash(type:*)"
          "Bash(where:*)"
          "Bash(uname:*)"
          "Bash(pgrep:*)"
          "Bash(ps:*)"
          # File inspection commands
          "Bash(file:*)"
          "Bash(wc:*)"
          # Nix read-only commands
          "Bash(nix search:*)"
          "Bash(nix show-config:*)"
          "Bash(nix flake metadata:*)"
          "Bash(nix flake show:*)"
          "Bash(nix profile diff-closures:*)"
          "Bash(nix eval:*)"
          "Bash(nix why-depends:*)"
          "Bash(nix store diff-closures:*)"
          # Package manager read-only commands
          "Bash(npm view:*)"
          "Bash(npm list:*)"
          "Bash(npm outdated:*)"
          "Bash(conda list:*)"
          "Bash(pip list:*)"
          "Bash(yarn list:*)"
          # Home Manager read-only commands
          "Bash(hm news:*)"
          "Bash(hm packages:*)"
          "Bash(home-manager news:*)"
          "Bash(home-manager generations:*)"
          # Utility commands
          "Bash(jq:*)"
          "Bash(mdfind:*)"
          "Bash(tldr:*)"
          "Read"
          "WebFetch"
          "WebSearch"
          "Write"
          "Edit(//Users/achhina/.config/**)"
          "mcp__context7__*"
          "mcp__plugin_episodic-memory_episodic-memory__*"
          "Glob"
          "Grep"
          "Task"
          "Skill"
          "SlashCommand"
          "TodoWrite"
          "NotebookEdit"
          "AskUserQuestion"
        ];

        deny = [
          "Bash(git commit --no-verify:*)"
        ];

        additionalDirectories = [
          "~/docs"
          "/tmp"
        ];
      };

      model = "sonnet";

      statusLine = {
        type = "command";
        command = "input=$(cat); cwd=$(echo \"$input\" | jq -r '.workspace.current_dir'); model=$(echo \"$input\" | jq -r '.model.display_name'); output_style=$(echo \"$input\" | jq -r '.output_style.name // \"default\"'); total_input=$(echo \"$input\" | jq -r '.context_window.total_input_tokens'); total_output=$(echo \"$input\" | jq -r '.context_window.total_output_tokens'); context_size=$(echo \"$input\" | jq -r '.context_window.context_window_size'); if [ \"$context_size\" != \"null\" ] && [ \"$context_size\" != \"0\" ]; then total_tokens=$((total_input + total_output)); usage_pct=$((total_tokens * 100 / context_size)); else usage_pct=0; fi; cd \"$cwd\" 2>/dev/null; git_branch=$(git --no-optional-locks branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \\(.*\\)/ (\\1)/'); if [ \"$total_input\" != \"null\" ] && [ \"$total_output\" != \"null\" ]; then input_k=$((total_input / 1000)); output_k=$((total_output / 1000)); token_info=\" [\${input_k}K↓ \${output_k}K↑ \${usage_pct}%%]\"; else token_info=\"\"; fi; printf \"\\033[32m$(whoami)@$(hostname -s) $(basename \"$cwd\")\${git_branch}\\033[0m \\033[36m[\${model}]\\033[0m\"; [ -n \"$token_info\" ] && printf \"\\033[33m\${token_info}\\033[0m\"";
      };

      alwaysThinkingEnabled = true;

      autoUpdates = true;

      theme = "dark";

      # Custom agents
      agents = [
        {
          name = "github-automation";
          description = "GitHub issue and PR creation with template discovery";
          tools = [
            "Read"
            "Write"
            "Grep"
            "Glob"
            "Bash"
            "AskUserQuestion"
          ];
        }
      ];

      # Plugin configuration
      # Marketplaces contain multiple plugins
      extraKnownMarketplaces = {
        superpowers-marketplace = {
          source = {
            source = "github";
            repo = "obra/superpowers-marketplace";
          };
          autoUpdate = true;
        };
        claude-code-workflows = {
          source = {
            source = "github";
            repo = "wshobson/agents";
          };
          autoUpdate = true;
        };
      };

      # Standalone plugins from GitHub
      plugins = {
        d3js = {
          source = {
            source = "github";
            repo = "chrisvoncsefalvay/claude-d3js-skill";
          };
        };
      };

      enabledPlugins = {
        "superpowers@superpowers-marketplace" = true;
        "episodic-memory@superpowers-marketplace" = true;
        "shell-scripting@claude-code-workflows" = true;
        "python-development@claude-code-workflows" = false;
        "javascript-typescript@claude-code-workflows" = true;
        "debugging-toolkit@claude-code-workflows" = true;
        "tdd-workflows@claude-code-workflows" = true;
        "d3js" = true;
      };

      # Session hooks
      hooks = {
        SessionStart = [
          {
            hooks = [
              {
                type = "command";
                command = "${softwareDevelopmentDetector}";
              }
              {
                type = "command";
                command = "${pythonProjectDetector}";
              }
            ];
          }
        ];
      };
    };
  };

  # Ensure Claude Code directories exist for plugin installations
  # These directories will contain both declaratively-managed symlinks (from Home Manager)
  # and dynamically-created files (from plugin installations)
  home.file = {
    # Force overwrite settings.json to allow reset on hm switch
    # The activation scripts will convert it from symlink to mutable file with backup
    ".claude/settings.json".force = true;

    # Create .keep files to ensure directories exist
    ".claude/commands/.keep".text = "";
    ".claude/agents/.keep".text = "";

    # Deploy additional context files for progressive disclosure
    ".claude/SOFTWARE_PRINCIPLES.md".source = ./context/SOFTWARE_PRINCIPLES.md;
    ".claude/PYTHON.md".source = ./context/PYTHON.md;
  };

  # Backup existing mutable settings.json before Home Manager regenerates it
  # This runs before writeBoundary to preserve user modifications
  home.activation.backupClaudeSettings = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    SETTINGS_FILE="$HOME/.claude/settings.json"
    BACKUP_FILE="$HOME/.claude/settings.json.backup"

    # Only backup if the file exists and is a regular file (not a symlink)
    # This captures any modifications Claude Code made during the session
    if [ -f "$SETTINGS_FILE" ] && [ ! -L "$SETTINGS_FILE" ]; then
      $VERBOSE_ECHO "Backing up mutable Claude Code settings to settings.json.backup"
      $DRY_RUN_CMD cp "$SETTINGS_FILE" "$BACKUP_FILE"
    fi
  '';

  # Convert settings.json from symlink to mutable file
  # This runs after writeBoundary, which creates the symlink to Nix store
  home.activation.makeClaudeSettingsMutable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS_FILE="$HOME/.claude/settings.json"

    # If settings.json is a symlink, convert it to a mutable copy
    if [ -L "$SETTINGS_FILE" ]; then
      $VERBOSE_ECHO "Converting Claude Code settings from symlink to mutable file"
      # Copy the content to a temporary file
      $DRY_RUN_CMD cp -L "$SETTINGS_FILE" "$SETTINGS_FILE.tmp"
      # Remove the symlink
      $DRY_RUN_CMD rm "$SETTINGS_FILE"
      # Move the copy to the final location
      $DRY_RUN_CMD mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    fi

    # Ensure settings.json is writable (whether freshly created or already existing)
    if [ -f "$SETTINGS_FILE" ]; then
      $DRY_RUN_CMD chmod u+w "$SETTINGS_FILE"
    fi
  '';

  # Install Claude Code via npm if not available
  # This allows us to get the latest version without waiting for nixpkgs updates
  home.activation.installClaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NPM_PREFIX="$HOME/.local/share/npm"

    # Check if claude command exists in npm global bin directory
    if ! [ -x "$NPM_PREFIX/bin/claude" ]; then
      $VERBOSE_ECHO "Claude Code not found, installing via npm..."
      $DRY_RUN_CMD mkdir -p "$NPM_PREFIX"
      $DRY_RUN_CMD ${pkgs.nodejs}/bin/npm install -g --prefix "$NPM_PREFIX" @anthropic-ai/claude-code
    else
      $VERBOSE_ECHO "Claude Code already installed via npm"
    fi
  '';

  # TEMPORARY PATCH: Fix episodic-memory plugin duplicate hooks issue
  # Reference: https://github.com/obra/episodic-memory/issues/21
  # Fixed by PR: https://github.com/obra/episodic-memory/pull/20 (not yet merged)
  #
  # ISSUE EXPLANATION:
  # Claude Code automatically loads hooks/hooks.json from plugins by convention.
  # The episodic-memory plugin incorrectly includes "hooks": "./hooks/hooks.json"
  # in its plugin.json, causing the same hooks file to be loaded twice, which
  # triggers the error:
  #   "Duplicate hooks file detected: ./hooks/hooks.json resolves to already-loaded
  #    file /Users/user/.claude/plugins/cache/episodic-memory/hooks/hooks.json"
  #
  # This activation script removes the redundant hooks field from plugin.json.
  # This patch can be removed once PR #20 is merged and released upstream.
  home.activation.patchEpisodicMemoryHooks = lib.hm.dag.entryAfter [ "installClaude" ] ''
    PLUGIN_JSON="$HOME/.claude/plugins/cache/episodic-memory/.claude-plugin/plugin.json"

    if [ -f "$PLUGIN_JSON" ]; then
      # Check if the problematic hooks field exists
      if ${pkgs.jq}/bin/jq -e '.hooks' "$PLUGIN_JSON" >/dev/null 2>&1; then
        $VERBOSE_ECHO "Patching episodic-memory plugin.json to remove duplicate hooks field"
        # Remove the hooks field using jq and preserve formatting
        $DRY_RUN_CMD ${pkgs.jq}/bin/jq 'del(.hooks)' "$PLUGIN_JSON" > "$PLUGIN_JSON.tmp"
        $DRY_RUN_CMD mv "$PLUGIN_JSON.tmp" "$PLUGIN_JSON"
      fi
    fi
  '';
}
