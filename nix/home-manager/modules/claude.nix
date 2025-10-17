{ config, pkgs, lib, ... }:

{
  # Claude Code settings configuration
  # Managed declaratively through Home Manager

  programs.claude-code = {
    enable = true;

    commands = {
      debug-error = ''
        Systematically debug and fix the error using this approach:

        1. **Understand the Error**
           - Read the full error message and stack trace
           - Identify the error type and location
           - Note any relevant context from the error output

        2. **Reproduce the Issue**
           - Identify the steps or conditions that trigger the error
           - Verify the error is reproducible
           - Note any patterns or edge cases

        3. **Investigate Root Cause**
           - Examine the code at the error location
           - Check recent changes that might have introduced the issue
           - Review related code paths and dependencies
           - Look for common issues (null references, type mismatches, logic errors)

        4. **Propose Solution**
           - Explain the root cause clearly
           - Suggest one or more fix approaches
           - Consider edge cases and side effects
           - Discuss trade-offs if multiple solutions exist

        5. **Implement Fix**
           - Apply the chosen solution
           - Add defensive checks if appropriate
           - Update error handling if needed

        6. **Verify Fix**
           - Test that the error no longer occurs
           - Run existing tests to ensure no regressions
           - Test edge cases

        Arguments: $ARGUMENTS (optional: error message, file path, or description)

        Please be thorough and methodical. If you need more information, ask before proceeding.
      '';
    };

    settings = {
      env = {
        BASH_DEFAULT_TIMEOUT_MS = "300000";
        BASH_MAX_TIMEOUT_MS = "600000";
      };

      includeCoAuthoredBy = false;

      permissions = {
        allow = [
          "Bash(cat:*)"
          "Bash(echo:*)"
          "Bash(find:*)"
          "Bash(fd:*)"
          "Bash(git add:*)"
          "Bash(git commit:*)"
          "Bash(git log:*)"
          "Bash(grep:*)"
          "Bash(head:*)"
          "Bash(hm:*)"
          "Bash(home-manager:*)"
          "Bash(just:*)"
          "Bash(ls:*)"
          "Bash(mkdir:*)"
          "Bash(nix:*)"
          "Bash(nix-channel:*)"
          "Bash(nix-shell:*)"
          "Bash(nix-collect-garbage:*)"
          "Bash(npm:*)"
          "Bash(nvim:*)"
          "Bash(sed:*)"
          "Bash(python:*)"
          "Bash(rg:*)"
          "Bash(tail:*)"
          "Bash(tmux list-:*)"
          "Bash(tmux show-:*)"
          "Bash(tmux display:*)"
          "Bash(tmux has-session:*)"
          "Bash(tmux capture-pane:*)"
          "Read"
          "WebFetch"
          "WebSearch"
          "Write"
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
    };
  };
}
