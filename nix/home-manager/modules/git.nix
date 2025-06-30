{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    # Include private configuration (user name, email, etc.)
    # includes = [
    #   { path = "~/.config/secrets/git/config"; }
    # ];

    # Core configuration
    extraConfig = {
      pull.rebase = true;

      core = {
        # Better interop between Mac & other OSs
        # Mac performs unicode decomposition (NFD) when handling unicode filenames
        # Other OSs use NFC. This setting normalizes to prevent file re-addition issues
        precomposeUnicode = true;
        quotePath = false;
        pager = "delta";
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
      delta.navigate = true; # use n and N to move between diff sections

      # Merge and diff settings
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
    };

    # Git aliases
    aliases = {
      s = "status";
      cm = "commit --message";
      root = "rev-parse --show-toplevel";
      amend = "commit --amend --no-edit";
      unstage = "reset HEAD --";
      undo = "reset --soft HEAD^";
      whois = "!sh -c 'git log -i -1 --pretty=\"format:%an <%ae>\n\" --author=\"$1\"' -";
      whatis = "show -s --pretty='tformat:%h (%s, %ad)' --date=short";
      pip = "shortlog --summary --email --numbered --regexp-ignore-case --extended-regexp";
      aliases = "!git config --get-regexp 'alias.*' | colrm 1 6 | sed 's/[ ]/ = /'";
      diffstat = "diff --stat -r";
    };

    # Global ignore patterns
    ignores = [
      # Claude Code local settings
      "**/.claude/settings.local.json"
    ];
  };
}
