{ config, pkgs, lib, ... }:

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

  # Terminal emulator
  programs.ghostty = {
    enable = true;
    package = null; # Don't install ghostty, just manage config

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

  # Zsh shell configuration
  programs.zsh = {
    enable = true;

    autocd = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    defaultKeymap = "emacs";

    setOptions = [
      "GLOB_DOTS" # include hidden files in glob patterns
      "AUTO_PUSHD" # automatically push directories to stack
      "HIST_IGNORE_DUPS" # don't record consecutive duplicate commands
      "HIST_IGNORE_SPACE" # don't record commands starting with space
      "COMPLETE_IN_WORD" # complete from cursor position, not just end
    ];

    completionInit = ''
      # https://github.com/Aloxaf/fzf-tab?tab=readme-ov-file
      # disable sort when completing `git checkout`
      zstyle ':completion:*:git-checkout:*' sort false
      # set descriptions format to enable group support
      # NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
      zstyle ':completion:*:descriptions' format '[%d]'
      # set list-colors to enable filename colorizing
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      # force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
      zstyle ':completion:*' menu no
      # include hidden files in completion
      zstyle ':completion:*' file-patterns '%p(D):globbed-files' '*:all-files'
      # configure cd completion to show directory stack when using cd -
      zstyle ':completion:*:directory-stack' list-colors ''${(s.:.)LS_COLORS}
      # case insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
      # preview directory's content with eza when completing cd (include hidden files)
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --all $realpath'
      # custom fzf flags - use tab for cycling, ctrl-space for accept
      # NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
      zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:down,shift-tab:up,ctrl-space:accept
      # To make fzf-tab follow FZF_DEFAULT_OPTS.
      # NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
      zstyle ':fzf-tab:*' use-fzf-default-opts yes
      # switch group using `<` and `>`
      zstyle ':fzf-tab:*' switch-group '<' '>'
      # use tmux floating pane
      zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
      # configure popup size to prevent small menus
      zstyle ':fzf-tab:*' popup-min-size 65 12
      zstyle ':fzf-tab:*' popup-pad 8 3

      autoload -Uz compinit
      compinit
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

    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
    ];

    historySubstringSearch.enable = true;

    initExtra = ''
      # Zsh-autosuggestions: bind right arrow to accept suggestion
      bindkey '^[[C' autosuggest-accept

      # History substring search: disable highlighting
      HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='none'
      HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='none'
    '';

    envExtra = ''
      ${lib.optionalString pkgs.stdenv.isDarwin ''
        # Fallback for macOS: ensure Nix daemon is sourced
        # macOS updates wipe /etc/zshrc, breaking system-wide Nix initialization
        # See: https://github.com/NixOS/nix/issues/6117
        [[ ! $(command -v nix) && -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]] && source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      ''}

      [[ -f $XDG_CONFIG_HOME/secrets/.secrets ]] && source $XDG_CONFIG_HOME/secrets/.secrets
    '';

    # Ensure ~/bin takes precedence over system and Nix paths
    #
    # We prepend ~/bin in ~/.zprofile instead of ~/.zshenv because of macOS's
    # path_helper utility (in /etc/zprofile) which reorganizes PATH and would
    # move ~/bin to the end.
    # See: https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2
    #
    # Shell loading order (login shells):
    #   1. /etc/zshenv
    #   2. ~/.zshenv
    #   3. /etc/zprofile      <- macOS: path_helper runs here, reorganizes PATH
    #   4. ~/.zprofile        <- We prepend ~/bin here (after path_helper)
    #   5. /etc/zshrc
    #   6. ~/.zshrc
    #
    # This works on all platforms:
    #   - macOS: Runs after path_helper, ensuring ~/bin stays first
    #   - Linux: No path_helper exists, simple prepend in .zprofile works fine
    profileExtra = ''
      export PATH="$HOME/bin:$PATH"
    '';

    shellAliases = {
      config = "$XDG_CONFIG_HOME";
      g = "git";
      gcd = "$(git rev-parse --show-toplevel)";
      hm = "home-manager switch --flake ~/.config/nix";
      home-manager = "home-manager switch --flake ~/.config/nix";
      l = "eza";
      ll = "eza --all --long";
      lt = "eza --tree --all --level 3";

      # fd aliases with hyperlink support
      fd = "fd --hyperlink";
      fdf = "fd --type f --hyperlink";
      fdd = "fd --type d --hyperlink";

      # Mermaid CLI with dynamic Chrome path
      mmdc = "PUPPETEER_EXECUTABLE_PATH=\"$(find $HOME/.cache/puppeteer/chrome-headless-shell -name 'chrome-headless-shell' -type f 2>/dev/null | head -1)\" command mmdc";

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
}
