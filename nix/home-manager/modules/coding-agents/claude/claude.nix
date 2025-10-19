{
  # Claude Code settings configuration
  # Managed declaratively through Home Manager

  programs.claude-code = {
    enable = true;

    commands = {
      debug-error = ./slash-commands/debug-error.md;
      code-review = ./slash-commands/code-review.md;
      code = ./slash-commands/code.md;
    };

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
}
