{ config, pkgs, lib, ... }:

{
  # Claude Code settings configuration
  # Managed declaratively through Home Manager
  #
  # NOTE: Claude Code cannot read symlinks, so we use activation scripts
  # to copy command files instead of the default symlink behavior.

  programs.claude-code = {
    enable = true;
    package = null; # Don't install claude-code via Nix, use npm install instead

    # Don't use the built-in commands option (creates symlinks)
    # Instead, we'll use activation scripts to copy files

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
          "Read"
          "WebFetch"
          "WebSearch"
          "Write"
          "mcp__context7__get-library-docs"
          "mcp__context7__resolve-library-id"
        ];

        deny = [
          "Bash(git commit --no-verify:*)"
        ];

        additionalDirectories = [
          "~/docs"
          "/tmp"
          "~/.cache"
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
      extraKnownMarketplaces = {
        superpowers-marketplace = {
          source = {
            source = "github";
            repo = "obra/superpowers-marketplace";
          };
        };
      };

      enabledPlugins = {
        "superpowers@superpowers-marketplace" = true;
      };
    };
  };

  # Copy slash commands to skills directory (Claude Code 2.0+ uses .claude/skills/)
  # Note: Claude Code can't read symlinks, so we copy instead
  home.activation.claudeCommands = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.claude/skills"
    $DRY_RUN_CMD cp -f "${./slash-commands/debug-error.md}" "$HOME/.claude/skills/debug-error.md"
    $DRY_RUN_CMD cp -f "${./slash-commands/code-review.md}" "$HOME/.claude/skills/code-review.md"
    $DRY_RUN_CMD cp -f "${./slash-commands/code.md}" "$HOME/.claude/skills/code.md"
  '';

  # Install Claude Code via npm if not available
  # This allows us to get the latest version without waiting for nixpkgs updates
  home.activation.installClaude = lib.hm.dag.entryAfter ["writeBoundary"] ''
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
