{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    # Include private configuration (user name, email, etc.)
    includes = [
      { path = "~/.config/secrets/git/config"; }
    ];

    # Core configuration
    settings = {
      pull.rebase = true;
      rebase.autoStash = true;

      core = {
        # Better interop between Mac & other OSs
        # Mac performs unicode decomposition (NFD) when handling unicode filenames
        # Other OSs use NFC. This setting normalizes to prevent file re-addition issues
        precomposeUnicode = true;
        quotePath = false;
        pager = "delta";
        excludesfile = "~/.config/git/ignore";
      };

      # Git LFS configuration
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };

      # Delta (diff tool) configuration
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true; # use n and N to move between diff sections
        line-numbers = true;
        side-by-side = true;
        syntax-theme = "TwoDark";
        features = "decorations";
        hyperlinks = true; # Enable clickable hyperlinks
        decorations = {
          commit-decoration-style = "bold yellow box ul";
          file-style = "bold yellow ul";
          file-decoration-style = "none";
        };
      };

      # Merge and diff settings
      merge = {
        conflictstyle = "diff3";
        tool = "vimdiff";
      };
      diff = {
        colorMoved = "default";
        algorithm = "histogram";
      };

      # Performance and security improvements
      rerere.enabled = true; # Remember conflict resolutions
      branch.autosetupmerge = "always";
      branch.autosetuprebase = "always";
      push.default = "simple";
      push.autoSetupRemote = true;

      # Better logging
      log.date = "relative";

      # Improved status
      status = {
        showUntrackedFiles = "all";
        submoduleSummary = true;
      };

      # Git aliases
      alias = {
        # Basic operations
        s = "status";
        a = "add";
        cm = "commit --message";
        amend = "commit --amend --no-edit";

        # Branch and checkout operations
        co = "checkout";
        cob = "checkout -b";
        br = "branch";

        # Modern Git commands (available in Git 2.23+)
        sw = "switch";                    # Switch branches
        swc = "switch -c";                # Create and switch to new branch
        swd = "switch --detach";          # Switch to commit in detached HEAD
        restore = "restore";              # Restore files from index/commit
        rs = "restore --staged";          # Unstage files (modern alternative to reset HEAD)
        rw = "restore --worktree";        # Restore working tree files

        # Stash operations
        ss = "stash save";
        sa = "stash apply";
        sd = "stash drop";
        sl = "stash list";

        # Reset and undo operations
        unstage = "reset HEAD --";
        undo = "reset --soft HEAD^";

        # Repository navigation
        root = "rev-parse --show-toplevel";

        # Information and inspection
        whois = "!sh -c 'git log -i -1 --pretty=\"format:%an <%ae>\n\" --author=\"$1\"' -";
        whatis = "show -s --pretty='tformat:%h (%s, %ad)' --date=short";
        pip = "shortlog --summary --email --numbered --regexp-ignore-case --extended-regexp";
        aliases = "!git config --get-regexp 'alias.*' | colrm 1 6 | sed 's/[ ]/ = /'";
        diffstat = "diff --stat -r";

        # Enhanced logging
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        lga = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all";
        lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
        lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";

        # Productivity workflows
        acp = "!f() { git add -A && git commit -m \"$1\" && git push; }; f";
        acm = "!f() { git add -u && git commit -m \"$1\"; }; f";
        pushf = "push --force-with-lease";

        # Remote operations
        pom = "push origin main";
        puma = "pull upstream main";
        fetch-all = "fetch --all --prune";

        # PR workflow
        pr = "!f() { base=\${1:-origin/main}; git diff $base...HEAD; }; f";
      };
    } // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
      # macOS-specific settings
      credential.helper = "osxkeychain";
    };

    # Global ignore patterns
    ignores = [
      # Claude Code local settings
      "**/.claude/settings.local.json"
      "CLAUDE.local.md"
    ];
  };

  # GitHub CLI configuration
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;

    settings = {
      git_protocol = "https";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";

      aliases = {
        # PR workflow
        co = "pr checkout";
        prc = "pr create";
        prd = "pr create --draft";
        prv = "pr view";
        prm = "pr merge";
        prl = "pr list";
        prr = "pr review";
        prs = "pr status";

        # Issue management
        ic = "issue create";
        iv = "issue view";
        il = "issue list";

        # Repository operations
        rv = "repo view";
        rf = "repo fork";
        rc = "repo clone";

        # Release management
        rl = "release list";
        rcr = "release create";
        rv-rel = "release view";
      };

      hosts = {
        "github.com" = {
          git_protocol = "ssh";
          user = config.home.username;
        };
      };
    };
  };
}
