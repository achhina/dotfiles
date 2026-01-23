{ pkgs, lib, ... }:

let
  # Architecture detection for Intel-specific workarounds
  isIntelDarwin = pkgs.stdenv.system == "x86_64-darwin";
in
{
  # Enable direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Enable zoxide for smarter directory navigation
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Readline configuration
  programs.readline = {
    enable = true;
    variables = {
      # Disable terminal bell
      bell-style = "none";

      # Completion enhancements
      show-all-if-ambiguous = true;
      show-all-if-unmodified = true;
      completion-ignore-case = true;
      completion-map-case = true;
      colored-stats = true;
      colored-completion-prefix = true;
      mark-symlinked-directories = true;
      menu-complete-display-prefix = true;
      visible-stats = true;

      # Editing improvements
      skip-completed-text = true;

      # History navigation
      history-preserve-point = true;
      revert-all-at-newline = true;

      # Display settings
      page-completions = false;
      completion-query-items = 200;
      echo-control-characters = false;
    };

    bindings = {
      # Arrow keys for partial history search
      "\\e[A" = "history-search-backward";
      "\\e[B" = "history-search-forward";
    };
  };

  # Terminal emulator
  programs.ghostty = {
    enable = true;
    # Disable package installation on Intel macOS, use ghostty-bin on Apple Silicon
    package = if isIntelDarwin then null else pkgs.ghostty-bin;

    settings = {
      # Theme and font settings
      theme = "Catppuccin Mocha";
      font-family = "FiraCode Nerd Font Mono";

      # SSH improvements (Ghostty 1.2.0+)
      shell-integration-features = "ssh-env,ssh-terminfo";

      # Compromise, because when left on it's harder to autoupdate OS.
      confirm-close-surface = false;

      # Claude Code shift+enter keybind support
      # See: https://github.com/anthropics/claude-code/issues/1282
      keybind = "shift+enter=text:\\x1b\\r";
    }
    // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
      # MacOS settings
      macos-option-as-alt = true;
      macos-titlebar-style = "hidden";
      macos-icon = "chalkboard";
      macos-auto-secure-input = true;
    };
  };

  # JankyBorders service for window borders (macOS only)
  services.jankyborders = pkgs.lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    settings = {
      style = "round";
      width = 6.0;
      hidpi = "off";
      active_color = "0xff0099cc";
      inactive_color = "0xff414550";
      blacklist = ''"iPhone Mirroring"'';
    };
  };

  # Docker CLI - let Docker Desktop manage config.json
  # programs.docker-cli disabled to prevent cross-device link errors
  # Docker Desktop will manage ~/.docker/config.json directly

  # Starship prompt configuration
  programs.starship = {
    enable = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format =
        let
          opening_glpyh = "";
          closing_glyph = "";
          sep = "";
        in
        "[${opening_glpyh}](color_orange)"
        + "$os"
        + "$username"
        + "[${sep}](bg:color_yellow fg:color_orange)"
        + "$directory"
        + "[${sep}](fg:color_yellow bg:color_aqua)"
        + "$git_branch"
        + "$git_status"
        + "[${sep}](fg:color_aqua bg:color_blue)"
        + "$python"
        + "$nodejs"
        + "[${sep}](fg:color_blue bg:color_bg3)"
        + "$docker_context"
        + "$conda"
        + "[${sep}](fg:color_bg3 bg:color_bg1)"
        + "$time"
        + "[${closing_glyph}](fg:color_bg1)"
        + "$line_break$character";

      palette = "gruvbox_dark";

      palettes.gruvbox_dark = {
        color_fg0 = "#fbf1c7";
        color_bg1 = "#3c3836";
        color_bg3 = "#665c54";
        color_blue = "#458588";
        color_aqua = "#689d6a";
        color_green = "#98971a";
        color_orange = "#d65d0e";
        color_purple = "#b16286";
        color_red = "#cc241d";
        color_yellow = "#d79921";
      };

      os = {
        disabled = false;
        style = "bg:color_orange fg:color_fg0";
        symbols = {
          Windows = "󰍲";
          Ubuntu = "󰕈";
          SUSE = "";
          Raspbian = "󰐿";
          Mint = "󰣭";
          Macos = "󰀵";
          Manjaro = "";
          Linux = "󰌽";
          Gentoo = "󰣨";
          Fedora = "󰣛";
          Alpine = "";
          Amazon = "";
          Android = "";
          Arch = "󰣇";
          Artix = "󰣇";
          EndeavourOS = "";
          CentOS = "";
          Debian = "󰣚";
          Redhat = "󱄛";
          RedHatEnterprise = "󱄛";
          Pop = "";
        };
      };

      username = {
        show_always = true;
        style_user = "bg:color_orange fg:color_fg0";
        style_root = "bg:color_orange fg:color_fg0";
        format = "[ $user ]($style)";
      };

      directory = {
        style = "fg:color_fg0 bg:color_yellow";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          Documents = "󰈙 ";
          Downloads = " ";
          Music = "󰝚 ";
          Pictures = " ";
          Developer = "󰲋 ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:color_aqua";
        format = "[[ $symbol $branch ](fg:color_fg0 bg:color_aqua)]($style)";
      };

      git_status = {
        style = "bg:color_aqua";
        format = "[[($all_status$ahead_behind )](fg:color_fg0 bg:color_aqua)]($style)";
      };

      nodejs = {
        disabled = false;
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      c = {
        symbol = " ";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      golang = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      java = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      haskell = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      python = {
        disabled = false;
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      docker_context = {
        symbol = "";
        style = "bg:color_bg3";
        format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)";
      };

      conda = {
        style = "bg:color_bg3";
        format = "[[ $symbol( $environment) ](fg:#83a598 bg:color_bg3)]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:color_bg1";
        format = "[[  $time ](fg:color_fg0 bg:color_bg1)]($style)";
      };

      line_break = {
        disabled = false;
      };

      character = {
        disabled = false;
        success_symbol = "[](bold fg:color_green)";
        error_symbol = "[](bold fg:color_red)";
        vimcmd_symbol = "[](bold fg:color_green)";
        vimcmd_replace_one_symbol = "[](bold fg:color_purple)";
        vimcmd_replace_symbol = "[](bold fg:color_purple)";
        vimcmd_visual_symbol = "[](bold fg:color_yellow)";
      };
    };
  };

  # Home Manager managed scripts
  home.file."bin/update" = {
    source = ../files/scripts/update;
    executable = true;
  };

  home.file."bin/man" = {
    source = ../files/scripts/man;
    executable = true;
  };

  home.file."bin/tmux-clean" = {
    source = ../files/scripts/tmux-clean;
    executable = true;
  };

  home.file."bin/tmux-here" = {
    source = ../files/scripts/tmux-here;
    executable = true;
  };

  home.file."bin/mux-here" = {
    source = ../files/scripts/mux-here;
    executable = true;
  };

  home.file."bin/ts" = {
    source = ../files/scripts/ts;
    executable = true;
  };

  home.file."bin/notify" = {
    source = ../files/scripts/notify;
    executable = true;
  };

  home.file."bin/parse-history" = {
    source = ../files/scripts/parse-history;
    executable = true;
  };

  home.file."bin/parse-claude-tools" = {
    source = ../files/scripts/parse-claude-tools;
    executable = true;
  };

  home.file."bin/worktree" = {
    source = ../files/scripts/worktree.py;
    executable = true;
  };

  home.file."bin/claude-doctor" = {
    source = ../files/scripts/claude-doctor.py;
    executable = true;
  };

  # Zsh shell configuration
  programs.zsh = {
    enable = true;

    autocd = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    defaultKeymap = "emacs";

    # initContent: Custom ZSH initialization code
    # Runs before oh-my-zsh initialization for early setup (PATH, fpath)
    # Note: oh-my-zsh plugin config (zstyle) must go elsewhere since completions load after oh-my-zsh
    initContent = ''
      # ============================================================================
      # Early initialization - PATH and tool setup
      # With tmux configured for non-login shells, this runs in all interactive shells
      # ============================================================================

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        # Initialize Homebrew (macOS)
        # This is idempotent and safe to run in every interactive shell
        if [[ -x /opt/homebrew/bin/brew ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
      ''}

      # Setup PATH
      # Since tmux spawns non-login shells, macOS path_helper won't run in panes
      # This is fine - we explicitly set the PATH we want here
      export PATH="$HOME/.local/bin:$HOME/.local/share/npm/bin:$HOME/bin:$PATH"

      # Docker completion now handled by oh-my-zsh docker plugin

      # Add custom completions directory to fpath (XDG data directory)
      fpath=($XDG_DATA_HOME/zsh/site-functions $fpath)
    '';

    setOptions = [
      "GLOB_DOTS" # include hidden files in glob patterns
      "AUTO_PUSHD" # automatically push directories to stack
      "HIST_IGNORE_DUPS" # don't record consecutive duplicate commands
      "HIST_IGNORE_SPACE" # don't record commands starting with space
      "COMPLETE_IN_WORD" # complete from cursor position, not just end
      "NO_BEEP" # disable beep on error in ZLE
      "NO_LIST_BEEP" # disable beep on ambiguous completion
      "NO_HIST_BEEP" # disable beep when accessing non-existent history
    ];

    completionInit = ''
      # Note: This entire section is SKIPPED by Home Manager when oh-my-zsh.enable = true
      # See: https://github.com/nix-community/home-manager/issues/3965
      #
      # When oh-my-zsh is enabled:
      # - compinit is handled by oh-my-zsh.sh with metadata-based cache invalidation
      # - Plugin configuration (zstyle) goes in oh-my-zsh.extraConfig instead
      #
      # This section only matters if you disable oh-my-zsh in the future.
    '';

    # Simple autoloadable functions
    siteFunctions = {
      "$" = ''
        "$@"
      '';

      refresh-env = ''
        unset __HM_SESS_VARS_SOURCED
        source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
        echo "Environment refreshed from Home Manager"
      '';
    };

    oh-my-zsh = {
      enable = true;
      custom = "$HOME/.oh-my-zsh/custom";
      plugins = [
        "fzf-tab"
        "docker"  # Handles docker completion caching automatically
      ] ++ lib.optionals pkgs.stdenv.isDarwin [
        "macos"   # macOS Finder integration and utilities
      ];

      # Extra settings for plugins (runs after oh-my-zsh initialization)
      extraConfig = ''
        # fzf-tab configuration
        # https://github.com/Aloxaf/fzf-tab
        zstyle ':completion:*:git-checkout:*' sort false
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' menu no
        zstyle ':completion:*' file-patterns '%p(D):globbed-files' '*:all-files'
        zstyle ':completion:*:directory-stack' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --all $realpath'
        zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:down,shift-tab:up,ctrl-space:accept
        # Disable FZF_DEFAULT_OPTS to prevent nested popups (--height/--border from defaults)
        zstyle ':fzf-tab:*' use-fzf-default-opts no
        zstyle ':fzf-tab:*' switch-group '<' '>'
        zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
        zstyle ':fzf-tab:*' popup-min-size 65 12
        zstyle ':fzf-tab:*' popup-pad 8 3
      '';
    };

    historySubstringSearch.enable = true;

    envExtra = ''
      # ============================================================================
      # .zshenv - Sourced for ALL shells (interactive, non-interactive, scripts)
      # Keep minimal: only environment variables needed by ALL invocations
      # Following expert consensus (romkatv, ZSH manual)
      # ============================================================================

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        # macOS Nix daemon fallback (only if nix command not found)
        # macOS updates can wipe /etc/zshrc breaking system-wide Nix init
        # See: https://github.com/NixOS/nix/issues/6117
        [[ ! $(command -v nix) && -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]] && \
          source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      ''}

      # Secrets (consider: do scripts actually need these?)
      [[ -f $XDG_CONFIG_HOME/secrets/.secrets ]] && source $XDG_CONFIG_HOME/secrets/.secrets

      # Application-specific environment variables
      export NPM_CONFIG_PREFIX="$HOME/.local/share/npm"
      export LESS="-Rq"

      # ZSH plugin configuration
      export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='none'
      export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='none'
    '';

    # .zprofile - Login shells only
    # Following romkatv's recommendation: avoid unless absolutely necessary
    # With tmux configured for non-login shells, this file won't run for tmux panes
    # Only runs for initial terminal login (which is fine - does nothing)
    # PATH and Homebrew initialization moved to .zshrc (initContent)
    profileExtra = ''
      # Left empty intentionally - all interactive setup moved to .zshrc
      # This follows expert consensus (romkatv, Nick Janetakis)
    '';

    shellAliases = {
      config = "$XDG_CONFIG_HOME";
      g = "git";
      gcd = "$(git rev-parse --show-toplevel)";
      hm = "home-manager switch --flake ~/.config/nix#${pkgs.stdenv.hostPlatform.system}";
      home-manager = "home-manager switch --flake ~/.config/nix#${pkgs.stdenv.hostPlatform.system}";
      l = "eza";
      ll = "eza --all --long";
      lt = "eza --tree --all --level 3";

      # fd aliases with hyperlink support
      fd = "fd --hyperlink";
      fdf = "fd --type f --hyperlink";
      fdd = "fd --type d --hyperlink";

      t = "tmux";
      ta = "tmux attach || tmux new-session";

      # Session management aliases
      tl = "tmux list-sessions";
      tk = "tmux kill-session -t";
      tn = "tmux new-session -s";
      tclean = "tmux-clean";

      # Tmuxinator shortcuts
      mux = "tmuxinator start";
      muxl = "tmuxinator list";
      muxd = "tmuxinator debug";

      v = "nvim";
    };

    history = {
      size = 100000;
      save = 100000;
    };
  };

  # Generate worktree completion after activation
  home.activation.generateWorktreeCompletion = lib.hm.dag.entryAfter [ "installPackages" ] ''
    COMPLETIONS_DIR="$XDG_DATA_HOME/zsh/site-functions"
    mkdir -p "$COMPLETIONS_DIR"
    if [ -x $HOME/bin/worktree ]; then
      $VERBOSE_ECHO "Generating worktree zsh completions..."
      # Add Nix profile and local bin to PATH for uv
      export PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:$PATH"
      if _WORKTREE_COMPLETE=zsh_source $HOME/bin/worktree > "$COMPLETIONS_DIR/_worktree"; then
        # Touch directory to trigger oh-my-zsh cache invalidation on success
        touch "$COMPLETIONS_DIR"
      else
        echo "Warning: Failed to generate worktree completions (exit code: $?)" >&2
      fi
    fi
  '';

  # Generate claude-doctor completion after activation
  home.activation.generateClaudeDoctorCompletion = lib.hm.dag.entryAfter [ "installPackages" ] ''
    COMPLETIONS_DIR="$XDG_DATA_HOME/zsh/site-functions"
    mkdir -p "$COMPLETIONS_DIR"
    if [ -x $HOME/bin/claude-doctor ]; then
      $VERBOSE_ECHO "Generating claude-doctor zsh completions..."
      export PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:$PATH"
      if _CLAUDE_DOCTOR_COMPLETE=zsh_source $HOME/bin/claude-doctor > "$COMPLETIONS_DIR/_claude_doctor"; then
        touch "$COMPLETIONS_DIR"
      else
        echo "Warning: Failed to generate claude-doctor completions (exit code: $?)" >&2
      fi
    fi
  '';
}
