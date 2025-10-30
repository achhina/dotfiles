{
  pkgs,
  lib,
  ...
}:

{
  # Claude Code settings configuration
  # Managed declaratively through Home Manager

  programs.claude-code = {
    enable = true;
    package = null; # Don't install claude-code via Nix, use npm install instead

    commandsDir = ./slash-commands;

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
          "Bash(man:*)"
          "Bash(mkdir:*)"
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
          "Bash(unzip:*)"
          "Bash(uv:*)"
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
          "Read"
          "WebFetch"
          "WebSearch"
          "Write"
          "mcp__context7__get-library-docs"
          "mcp__context7__resolve-library-id"
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
        command = "input=$(cat); cwd=$(echo \"$input\" | jq -r '.workspace.current_dir'); cd \"$cwd\" 2>/dev/null; git_branch=$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \\(.*\\)/ (\\1)/'); printf \"\\033[32m$(whoami)@$(hostname -s) $(basename \"$cwd\")\${git_branch}\\033[0m\"";
      };

      alwaysThinkingEnabled = true;

      autoUpdates = true;

      theme = "dark";

      # Plugin configuration
      # Marketplaces contain multiple plugins
      extraKnownMarketplaces = {
        superpowers-marketplace = {
          source = {
            source = "github";
            repo = "obra/superpowers-marketplace";
          };
        };
        claude-code-workflows = {
          source = {
            source = "github";
            repo = "wshobson/agents";
          };
        };
      };

      # Standalone plugins from GitHub
      plugins = { };

      enabledPlugins = {
        "superpowers@superpowers-marketplace" = true;
        "elements-of-style@superpowers-marketplace" = true;
        "shell-scripting@claude-code-workflows" = true;
        "python-development@claude-code-workflows" = true;
        "javascript-typescript@claude-code-workflows" = true;
        "debugging-toolkit@claude-code-workflows" = true;
        "tdd-workflows@claude-code-workflows" = true;
      };
    };
  };

  # Ensure Claude Code directories exist for plugin installations
  # These directories will contain both declaratively-managed symlinks (from Home Manager)
  # and dynamically-created files (from plugin installations)
  # Symlink skills from Home Manager source to runtime directory
  home.file =
    let
      skillsDir = ./skills;
      skillsExist = builtins.pathExists skillsDir;
      skills = if skillsExist then builtins.readDir skillsDir else {};
    in
    lib.mkMerge [
      # Force overwrite settings.json to allow reset on hm switch
      # The activation scripts will convert it from symlink to mutable file with backup
      {
        ".claude/settings.json".force = true;
      }
      # Create .keep files to ensure directories exist
      {
        ".claude/commands/.keep".text = "";
        ".claude/agents/.keep".text = "";
        ".claude/skills/.keep".text = "";
      }
      # Symlink skills from declarative source
      (lib.mapAttrs' (name: _: {
        name = ".claude/skills/${name}";
        value = {
          source = ./skills/${name};
        };
      }) skills)
    ];

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
}
