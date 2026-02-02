{
  pkgs,
  lib,
  config,
  ...
}:

let
  softwareDevelopmentDetector = pkgs.writeShellScript "software-development-detector.sh" (
    builtins.readFile ./hooks/software-development-detector.sh
  );

  pythonProjectDetector = pkgs.writeShellScript "python-project-detector.sh" (
    builtins.readFile ./hooks/python-project-detector.sh
  );

  neovimSessionBinder = pkgs.writeShellScript "neovim-session-binder.sh" (
    builtins.readFile ./hooks/neovim-session-binder.sh
  );

  blockFileWritingViaBash = pkgs.writeShellScript "block-file-writing-via-bash.sh" (
    builtins.readFile ./hooks/block-file-writing-via-bash.sh
  );

  # Load local overrides if they exist (separate file to simplify rebasing)
  overridesPath = ./claude-overrides.nix;
  hasOverrides = builtins.pathExists overridesPath;
  localOverrides =
    if hasOverrides then
      import overridesPath
    else
      {
        allowPermissions = [ ];
        denyPermissions = [ ];
        askPermissions = [ ];
        removeAllowPermissions = [ ];
        removeDenyPermissions = [ ];
        removeAskPermissions = [ ];
      };

  # Helper to filter out items
  filterOut = itemsToRemove: list: builtins.filter (x: !(builtins.elem x itemsToRemove)) list;

  # Base permissions defined here (upstream defaults)
  baseAllowPermissions = [
    "AskUserQuestion"
    "Bash(/usr/bin/man *)"
    "Bash(actionlint *)"
    "Bash(awk *)"
    "Bash(brew --cellar *)"
    "Bash(brew --prefix *)"
    "Bash(brew --repository *)"
    "Bash(brew --version *)"
    "Bash(brew commands *)"
    "Bash(brew config *)"
    "Bash(brew deps *)"
    "Bash(brew desc *)"
    "Bash(brew doctor *)"
    "Bash(brew help *)"
    "Bash(brew info *)"
    "Bash(brew leaves *)"
    "Bash(brew list *)"
    "Bash(brew outdated *)"
    "Bash(brew search *)"
    "Bash(brew tap-info *)"
    "Bash(brew uses *)"
    "Bash(btop *)"
    "Bash(cat *)"
    "Bash(check-upstream-issues *)"
    "Bash(claude-doctor *)"
    "Bash(col *)"
    "Bash(command *)"
    "Bash(conda list *)"
    "Bash(convert *)"
    "Bash(copier *)"
    "Bash(date *)"
    "Bash(diff *)"
    "Bash(docker compose *)"
    "Bash(docker container inspect *)"
    "Bash(docker container logs *)"
    "Bash(docker container ls *)"
    "Bash(docker container port *)"
    "Bash(docker container stats *)"
    "Bash(docker container top *)"
    "Bash(docker diff *)"
    "Bash(docker events *)"
    "Bash(docker history *)"
    "Bash(docker image history *)"
    "Bash(docker image inspect *)"
    "Bash(docker image ls *)"
    "Bash(docker images *)"
    "Bash(docker info *)"
    "Bash(docker inspect *)"
    "Bash(docker logs *)"
    "Bash(docker manifest inspect *)"
    "Bash(docker network inspect *)"
    "Bash(docker network ls *)"
    "Bash(docker port *)"
    "Bash(docker ps *)"
    "Bash(docker search *)"
    "Bash(docker stats *)"
    "Bash(docker system df *)"
    "Bash(docker system events *)"
    "Bash(docker system info *)"
    "Bash(docker top *)"
    "Bash(docker version *)"
    "Bash(docker volume inspect *)"
    "Bash(docker volume ls *)"
    "Bash(echo *)"
    "Bash(env *)"
    "Bash(fd *)"
    "Bash(file *)"
    "Bash(find *)"
    "Bash(gh api --method GET *)"
    "Bash(gh api --method=GET *)"
    "Bash(gh api -X GET *)"
    "Bash(gh api -XGET *)"
    "Bash(gh api repos/*/*/issues *)"
    "Bash(gh api repos/*/*/pulls *)"
    "Bash(gh api search/* *)"
    "Bash(gh attestation verify *)"
    "Bash(gh auth status *)"
    "Bash(gh browse *)"
    "Bash(gh cache list *)"
    "Bash(gh config get *)"
    "Bash(gh copilot *)"
    "Bash(gh gist list *)"
    "Bash(gh gpg-key list *)"
    "Bash(gh issue list *)"
    "Bash(gh issue view *)"
    "Bash(gh label list *)"
    "Bash(gh pr checks *)"
    "Bash(gh pr diff *)"
    "Bash(gh pr list *)"
    "Bash(gh pr view *)"
    "Bash(gh release list *)"
    "Bash(gh release view *)"
    "Bash(gh repo view *)"
    "Bash(gh run list *)"
    "Bash(gh run view *)"
    "Bash(gh search *)"
    "Bash(gh ssh-key list *)"
    "Bash(gh status *)"
    "Bash(gh workflow list *)"
    "Bash(gh workflow view *)"
    "Bash(git add *)"
    "Bash(git blame *)"
    "Bash(git branch *)"
    "Bash(git check-ignore *)"
    "Bash(git commit *)"
    "Bash(git config --get *)"
    "Bash(git config --list *)"
    "Bash(git diff *)"
    "Bash(git fetch *)"
    "Bash(git log *)"
    "Bash(git ls-files *)"
    "Bash(git ls-tree *)"
    "Bash(git merge-base *)"
    "Bash(git mv *)"
    "Bash(git rebase *)"
    "Bash(git remote *)"
    "Bash(git rev-parse *)"
    "Bash(git rm *)"
    "Bash(git show *)"
    "Bash(git status *)"
    "Bash(git worktree *)"
    "Bash(grep *)"
    "Bash(head *)"
    "Bash(hexdump *)"
    "Bash(hm *)"
    "Bash(hm news *)"
    "Bash(hm packages *)"
    "Bash(home-manager *)"
    "Bash(home-manager generations *)"
    "Bash(home-manager news *)"
    "Bash(htop *)"
    "Bash(ifconfig *)"
    "Bash(iostat *)"
    "Bash(jest *)"
    "Bash(jq *)"
    "Bash(just *)"
    "Bash(ls *)"
    "Bash(lsof *)"
    "Bash(magick *)"
    "Bash(man *)"
    "Bash(mdfind *)"
    "Bash(mdls *)"
    "Bash(mkdir *)"
    "Bash(mktemp *)"
    "Bash(mypy *)"
    "Bash(nix *)"
    "Bash(nix eval *)"
    "Bash(nix flake metadata *)"
    "Bash(nix flake show *)"
    "Bash(nix profile diff-closures *)"
    "Bash(nix search *)"
    "Bash(nix show-config *)"
    "Bash(nix store diff-closures *)"
    "Bash(nix why-depends *)"
    "Bash(nix-channel *)"
    "Bash(nix-collect-garbage *)"
    "Bash(nix-prefetch-url *)"
    "Bash(nix-shell *)"
    "Bash(nix-store *)"
    "Bash(npm *)"
    "Bash(npm list *)"
    "Bash(npm outdated *)"
    "Bash(npm view *)"
    "Bash(nvim *)"
    "Bash(pgrep *)"
    "Bash(pip list *)"
    "Bash(playwright *)"
    "Bash(pre-commit *)"
    "Bash(prettier *)"
    "Bash(printenv *)"
    "Bash(ps *)"
    "Bash(pstree *)"
    "Bash(pwd *)"
    "Bash(pytest *)"
    "Bash(python *)"
    "Bash(readlink *)"
    "Bash(refresh-env *)"
    "Bash(rg *)"
    "Bash(ruff *)"
    "Bash(rustfmt *)"
    "Bash(sed *)"
    "Bash(shellcheck *)"
    "Bash(sleep *)"
    "Bash(sort *)"
    "Bash(sphinx-build *)"
    "Bash(stat *)"
    "Bash(strings *)"
    "Bash(tail *)"
    "Bash(test *)"
    "Bash(timeout *)"
    "Bash(tldr *)"
    "Bash(tmux capture-pane *)"
    "Bash(tmux display *)"
    "Bash(tmux has-session *)"
    "Bash(tmux info *)"
    "Bash(tmux list-*)"
    "Bash(tmux show-*)"
    "Bash(tmux-mem-cpu-load *)"
    "Bash(top *)"
    "Bash(touch *)"
    "Bash(tree *)"
    "Bash(ty *)"
    "Bash(type *)"
    "Bash(uname *)"
    "Bash(unzip *)"
    "Bash(uv *)"
    "Bash(wc *)"
    "Bash(whence *)"
    "Bash(where *)"
    "Bash(which *)"
    "Bash(worktree *)"
    "Bash(yamllint *)"
    "Bash(yarn *)"
    "Bash(yarn list *)"
    "Bash(zip *)"
    "Bash(~/bin/man *)"
    "Edit(//${lib.removePrefix "/" config.xdg.configHome}/**)"
    "EnterPlanMode"
    "ExitPlanMode"
    "Glob"
    "Grep"
    "KillShell"
    "NotebookEdit"
    "Read"
    "Skill"
    "SlashCommand"
    "Task"
    "TaskCreate"
    "TaskGet"
    "TaskList"
    "TaskOutput"
    "TaskStop"
    "TaskUpdate"
    "TodoWrite"
    "WebFetch"
    "WebSearch"
    "Write"
    "mcp__context7__*"
    "mcp__plugin_neovim-integration_neovim__*"
  ];

  baseDenyPermissions = [
    # Git safety
    "Bash(git * --no-verify)" # Skips hooks
    "Bash(git * --no-verify *)"
    "Bash(git -C *)" # Breaks permission patterns
    "Bash(git --git-dir *)"
    "Bash(git --work-tree *)"
  ];

  baseAskPermissions = [
    # GitHub API - escape hatches for mutating methods (ask instead of deny)
    "Bash(gh api * --method POST *)"
    "Bash(gh api * --method=POST *)"
    "Bash(gh api * -X POST *)"
    "Bash(gh api * -XPOST *)"
    "Bash(gh api * --method PUT *)"
    "Bash(gh api * --method=PUT *)"
    "Bash(gh api * -X PUT *)"
    "Bash(gh api * -XPUT *)"
    "Bash(gh api * --method DELETE *)"
    "Bash(gh api * --method=DELETE *)"
    "Bash(gh api * -X DELETE *)"
    "Bash(gh api * -XDELETE *)"
    "Bash(gh api * --method PATCH *)"
    "Bash(gh api * --method=PATCH *)"
    "Bash(gh api * -X PATCH *)"
    "Bash(gh api * -XPATCH *)"

    # GitHub API - body-providing flags (infer POST/PATCH)
    "Bash(gh api * --input *)"
    "Bash(gh api * --field *)"
    "Bash(gh api * -f *)" # Shorthand for --field
    "Bash(gh api * -F *)" # Shorthand for --field (from file)
    "Bash(gh api * --raw-field *)"
  ];

  # Merge base permissions with local overrides
  finalAllowPermissions =
    (filterOut localOverrides.removeAllowPermissions baseAllowPermissions)
    ++ localOverrides.allowPermissions;

  finalDenyPermissions =
    (filterOut localOverrides.removeDenyPermissions baseDenyPermissions)
    ++ localOverrides.denyPermissions;

  finalAskPermissions =
    (filterOut localOverrides.removeAskPermissions baseAskPermissions) ++ localOverrides.askPermissions;

  # Where skillsDir gets deployed at runtime
  skillsDeployedPath = "$HOME/.claude/skills";

  # Plugin configuration for dynamic skill generation
  enabledPlugins = {
    "superpowers@superpowers-marketplace" = true;
    "tdd-workflows@claude-code-workflows" = true;
  };
in
{
  programs.claude-code = {
    enable = true;
    package = null;

    # Commands: inline content (required format, not paths)
    commands = {
      # Static commands (inline content)
      comments = builtins.readFile ./commands/comments.md;
      conflicts = builtins.readFile ./commands/conflicts.md;
      issue = builtins.readFile ./commands/issue.md;
      learn = builtins.readFile ./commands/learn.md;
      pr = builtins.readFile ./commands/pr.md;
      update-docs = builtins.readFile ./commands/update-docs.md;

      # Dynamic command with agent substitution
      commit =
        let
          commitAgent = "commit";
          commandTemplate = builtins.readFile ./commands/commit.md;
        in
        builtins.replaceStrings
          [ "@commitAgent@" ]
          [ commitAgent ]
          commandTemplate;
    };

    memory.source = ./context/AGENTS.md;

    agentsDir = ./agents;

    # Skills: mix of paths (static) and inline (templated)
    skills = {
      # Static skills from directory
      commit-message = ./skills/commit-message;
      learn = ./skills/learn;
      mermaid = ./skills/mermaid;
      update-docs = ./skills/update-docs;

      # Dynamic skills handled via home.file below due to Home Manager module limitations
    };

    settings = {
      env = {
        BASH_DEFAULT_TIMEOUT_MS = "300000";
        BASH_MAX_TIMEOUT_MS = "600000";
        # Fallback value when not launched from Neovim to suppress MCP server errors
        # Neovim will override this with the actual socket path when launching Claude
        NVIM_MCP_SOCKET = "/dev/null";
      };

      includeCoAuthoredBy = false;

      permissions = {
        allow = finalAllowPermissions;
        deny = finalDenyPermissions;
        ask = finalAskPermissions;
        defaultMode = "acceptEdits";

        additionalDirectories = [
          "~/docs"
          "/tmp"
        ];
      };

      model = "sonnet";

      statusLine = {
        type = "command";
        command = "input=$(cat); cwd=$(echo \"$input\" | jq -r '.workspace.current_dir'); model=$(echo \"$input\" | jq -r '.model.display_name'); total_input=$(echo \"$input\" | jq -r '.context_window.total_input_tokens'); total_output=$(echo \"$input\" | jq -r '.context_window.total_output_tokens'); usage_pct=$(echo \"$input\" | jq -r '.context_window.used_percentage // 0' | awk '{printf \"%.0f\", $1}'); cd \"$cwd\" 2>/dev/null; git_branch=$(git --no-optional-locks branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \\(.*\\)/ (\\1)/'); if [ \"$total_input\" != \"null\" ] && [ \"$total_output\" != \"null\" ]; then input_k=$((total_input / 1000)); output_k=$((total_output / 1000)); token_info=\" [\${input_k}K↓ \${output_k}K↑ \${usage_pct}%%]\"; else token_info=\"\"; fi; printf \"\\033[32m$(whoami)@$(hostname -s) $(basename \"$cwd\")\${git_branch}\\033[0m \\033[36m[\${model}]\\033[0m\"; [ -n \"$token_info\" ] && printf \"\\033[33m\${token_info}\\033[0m\"";
      };

      alwaysThinkingEnabled = true;

      autoUpdates = true;

      theme = "dark";

      defaultPermissionMode = "acceptEdits";

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

      # Marketplaces contain multiple plugins
      # @upstream-issue: https://github.com/anthropics/claude-code/issues/16870
      # extraKnownMarketplaces is ignored by Claude Code - activation script workaround required
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
        claude-plugins-official = {
          source = {
            source = "github";
            repo = "anthropics/claude-plugins-official";
          };
          autoUpdate = true;
        };
        neovim-marketplace = {
          source = {
            source = "directory";
            path = "\${HOME}/.claude/plugins/marketplaces/neovim-marketplace";
          };
          autoUpdate = false;
        };
      };

      plugins = {
        d3js = {
          source = {
            source = "github";
            repo = "chrisvoncsefalvay/claude-d3js-skill";
          };
          autoUpdate = true;
        };
      };

      enabledPlugins = {
        "superpowers@superpowers-marketplace" = true;
        "double-shot-latte@superpowers-marketplace" = false;
        # @upstream-issue: https://github.com/anthropics/claude-code/issues/10113
        # Git-installed marketplace plugins have wrong path resolution causing ENOTDIR errors on skill loading
        "shell-scripting@claude-code-workflows" = true;
        "python-development@claude-code-workflows" = false;
        "javascript-typescript@claude-code-workflows" = true;
        "debugging-toolkit@claude-code-workflows" = true;
        "tdd-workflows@claude-code-workflows" = true;
        "d3js" = true;
        "neovim-integration@neovim-marketplace" = true;
        "github@claude-plugins-official" = false;
        "ralph-loop@claude-plugins-official" = true;
        "frontend-design@claude-plugins-official" = true;
        "code-review@claude-plugins-official" = true;
        "feature-dev@claude-plugins-official" = true;
        "code-simplifier@claude-plugins-official" = true;
        "pr-review-toolkit@claude-plugins-official" = true;
        "agent-sdk-dev@claude-plugins-official" = true;
        "pyright-lsp@claude-plugins-official" = true;
        "plugin-dev@claude-plugins-official" = true;
        "hookify@claude-plugins-official" = true;
      };

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
              {
                type = "command";
                command = "${neovimSessionBinder}";
              }
            ];
          }
        ];
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "${blockFileWritingViaBash}";
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

    ".claude/commands/.keep".text = "";
    ".claude/agents/.keep".text = "";

    # Deploy additional context files for progressive disclosure
    ".claude/SOFTWARE_PRINCIPLES.md".source = ./context/SOFTWARE_PRINCIPLES.md;
    ".claude/PYTHON.md".source = ./context/PYTHON.md;

    # Generate issue command with template paths substituted
    ".claude/commands/issue.md".source =
      let
        templatesDir = ./skills/github/templates;
        templateFiles = builtins.attrNames (builtins.readDir templatesDir);
        formatTemplateName =
          name:
          let
            withoutExt = builtins.head (builtins.match "(.*)\.md" name);
            withSpaces = builtins.replaceStrings [ "_" ] [ " " ] withoutExt;
            capitalize =
              str:
              builtins.concatStringsSep " " (
                map (
                  word:
                  "${lib.toUpper (builtins.substring 0 1 word)}${
                    builtins.substring 1 (builtins.stringLength word) word
                  }"
                ) (lib.splitString " " withSpaces)
              );
          in
          capitalize withSpaces;
        templateList = builtins.concatStringsSep "\n" (
          map (
            name: "- ${formatTemplateName name}: ${skillsDeployedPath}/github/templates/${name}"
          ) templateFiles
        );
      in
      pkgs.replaceVars ./commands/issue.md {
        fallbackTemplates = templateList;
      };

    # Deploy templated skills as directory structures (workaround for Home Manager module limitation)
    ".claude/skills/finalize/SKILL.md".text =
      let
        tddWorkflowsAgent =
          if enabledPlugins."tdd-workflows@claude-code-workflows" or false then
            "tdd-workflows:code-reviewer"
          else
            throw "finalize skill requires tdd-workflows plugin to be enabled";
        superpowersDebugging =
          if enabledPlugins."superpowers@superpowers-marketplace" or false then
            "superpowers:systematic-debugging"
          else
            throw "finalize skill requires superpowers plugin to be enabled";
        commentsSkill = "comments";
        commitSkill = "commit";
        skillTemplate = builtins.readFile ./skills/finalize/SKILL.md;
      in
      builtins.replaceStrings
        [ "@tddWorkflowsAgent@" "@superpowersDebugging@" "@commentsSkill@" "@commitSkill@" ]
        [ tddWorkflowsAgent superpowersDebugging commentsSkill commitSkill ]
        skillTemplate;

    ".claude/skills/comments/SKILL.md".text =
      let
        commentRemoverAgent = "comment-remover";
        skillTemplate = builtins.readFile ./skills/comments/SKILL.md;
      in
      builtins.replaceStrings [ "@commentRemoverAgent@" ] [ commentRemoverAgent ] skillTemplate;

    ".claude/skills/github/SKILL.md".text =
      let
        githubAutomationAgent = "github-automation";
        skillTemplate = builtins.readFile ./skills/github/SKILL.md;
      in
      builtins.replaceStrings [ "@githubAutomationAgent@" ] [ githubAutomationAgent ] skillTemplate;

    ".claude/skills/github/templates".source = ./skills/github/templates;
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

  # @upstream-issue: https://github.com/anthropics/claude-code/issues/16870
  # Claude Code ignores extraKnownMarketplaces in settings files, requiring manual registration
  # This activation script works around the bug by:
  # 1. Symlinking local marketplaces from Nix store to ~/.claude/plugins/marketplaces/
  # 2. Registering them via `claude plugin marketplace add` CLI command
  home.activation.installLocalMarketplace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MARKETPLACES_DIR="$HOME/.claude/plugins/marketplaces"
    $DRY_RUN_CMD mkdir -p "$MARKETPLACES_DIR"

    # Symlink neovim-marketplace
    MARKETPLACE_PATH="${./marketplace/neovim-marketplace}"
    MARKETPLACE_LINK="$MARKETPLACES_DIR/neovim-marketplace"

    if [ -d "$MARKETPLACE_PATH" ]; then
      $VERBOSE_ECHO "Installing neovim-marketplace to ~/.claude/plugins/marketplaces/"
      # Remove existing symlink if present
      if [ -L "$MARKETPLACE_LINK" ] || [ -e "$MARKETPLACE_LINK" ]; then
        $DRY_RUN_CMD rm -f "$MARKETPLACE_LINK"
      fi
      $DRY_RUN_CMD ln -s "$MARKETPLACE_PATH" "$MARKETPLACE_LINK"

      # Register marketplace with Claude Code (workaround for upstream bug)
      if command -v claude >/dev/null 2>&1; then
        $VERBOSE_ECHO "Registering neovim-marketplace with Claude Code"
        # Check if already registered by checking known_marketplaces.json
        KNOWN_MARKETPLACES="$HOME/.claude/plugins/known_marketplaces.json"
        if [ -f "$KNOWN_MARKETPLACES" ] && ! grep -q "neovim-marketplace" "$KNOWN_MARKETPLACES"; then
          $DRY_RUN_CMD claude plugin marketplace add "$MARKETPLACE_LINK" >/dev/null 2>&1 || true
        fi
      fi
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

  # Ensure Claude Code native installation exists
  # Uses the native installer which manages its own updates
  # Source: https://code.claude.com/docs/en/setup#installation
  home.activation.installClaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CLAUDE_BIN="$HOME/.local/bin/claude"

    # Check if claude binary exists at expected location
    if ! [ -x "$CLAUDE_BIN" ]; then
      $VERBOSE_ECHO "Claude Code not found, installing via native installer..."
      # Download and run the official installer from claude.ai
      ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | ${pkgs.bash}/bin/bash -s stable
      # Run claude install to complete setup
      if [ -x "$CLAUDE_BIN" ]; then
        $VERBOSE_ECHO "Running claude install to complete setup..."
        "$CLAUDE_BIN" install || true
      fi
    else
      $VERBOSE_ECHO "Claude Code native installation found at $CLAUDE_BIN"
    fi
  '';

}
