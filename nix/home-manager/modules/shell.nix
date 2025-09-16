{ config, pkgs, ... }:

{
  # Enable direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Terminal emulator
  programs.ghostty = {
    enable = true;
    package = null; # Don't install ghostty, just manage config

    settings =
      {
        # Theme and font settings
        theme = "catppuccin-mocha";
        font-family = "FiraCode Nerd Font Mono";

        # Compromise, because when left on it's harder to autoupdate OS.
        confirm-close-surface = false;
      }
      // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
        # MacOS settings
        macos-option-as-alt = true;
        macos-titlebar-style = "hidden";
        macos-icon = "chalkboard";
        macos-auto-secure-input = true;
      };
  };

  # Docker CLI configuration with credential helper
  programs.docker-cli = {
    enable = true;
    # Only provide completions, let Docker manage its own config
  };

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
    source = ../files/update;
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
      "GLOB_DOTS"           # include hidden files in glob patterns
      "AUTO_PUSHD"          # automatically push directories to stack
      "HIST_IGNORE_DUPS"    # don't record consecutive duplicate commands
      "HIST_IGNORE_SPACE"   # don't record commands starting with space
      "EXTENDED_GLOB"       # enable advanced globbing: ^, ~, #, ##, (...)
      "COMPLETE_IN_WORD"    # complete from cursor position, not just end
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

    # Custom autoloadable functions
    siteFunctions = {
      man = ''
        local MAN="/usr/bin/man"
        local MANPATHS=("/usr/share/man" "/usr/local/share/man" "/nix/var/nix/profiles/default/share/man" "$XDG_HOME/.nix-profile/share/man")

        if [ -n "$1" ]; then
            command "$MAN" "$@"
            return $?
        else
            if ! command -v fd >/dev/null 2>&1 || ! command -v fzf >/dev/null 2>&1; then
                echo "Error: fd and fzf are required for interactive man browsing" >&2
                return 1
            fi

            local selected
            selected=$(fd -tf -tl . "''${MANPATHS[@]}" 2>/dev/null | sed "s|.*/||" | sed "s|\..*||" | sort -u | fzf --reverse --preview="$MAN {} 2>/dev/null || echo 'Preview not available'")

            if [ -n "$selected" ]; then
                command "$MAN" "$selected"
            fi
        fi
      '';

      "$" = ''
        "$@"
      '';

      tmux-clean = ''
        if ! command -v tmux >/dev/null 2>&1; then
            echo "Error: tmux is not installed or not in PATH" >&2
            return 1
        fi

        if ! tmux info &>/dev/null; then
            echo "No tmux server running"
            return 0
        fi

        local current_session
        current_session=$(tmux display-message -p '#S' 2>/dev/null)

        if [ -z "$current_session" ]; then
            echo "Not inside a tmux session"
            return 1
        fi

        local sessions_to_kill
        sessions_to_kill=$(tmux list-sessions -F '#S' 2>/dev/null | grep -v "^$current_session$" || true)

        if [ -z "$sessions_to_kill" ]; then
            echo "No sessions to clean (only current session '$current_session' exists)"
            return 0
        fi

        echo "Killing tmux sessions except current ('$current_session'):"
        local count=0
        echo "$sessions_to_kill" | while read -r session; do
            if [ -n "$session" ]; then
                echo "  ✗ Killing session: $session"
                tmux kill-session -t "$session" 2>/dev/null || echo "    Failed to kill session: $session" >&2
                count=$((count + 1))
            fi
        done
        echo "Done! Cleaned $(echo "$sessions_to_kill" | wc -l | tr -d ' ') sessions"
      '';

      tmux-here = ''
        if ! command -v tmux >/dev/null 2>&1; then
            echo "Error: tmux is not installed or not in PATH" >&2
            return 1
        fi

        local session_name
        session_name=$(basename "$PWD" | tr '.' '_' | tr ' ' '_')

        if tmux has-session -t "$session_name" 2>/dev/null; then
            if [ -n "$TMUX" ]; then
                tmux switch-client -t "$session_name"
            else
                tmux attach-session -t "$session_name"
            fi
        else
            tmux new-session -d -s "$session_name" -c "$PWD"
            if [ -n "$TMUX" ]; then
                tmux switch-client -t "$session_name"
            else
                tmux attach-session -t "$session_name"
            fi
        fi
      '';

      mux-here = ''
        if ! command -v tmuxinator >/dev/null 2>&1; then
            echo "Error: tmuxinator is not installed" >&2
            echo "Falling back to tmux-here..."
            tmux-here
            return $?
        fi

        if [ -f ".tmuxinator.yml" ]; then
            tmuxinator start . || {
                echo "Failed to start tmuxinator project, falling back to tmux-here..." >&2
                tmux-here
            }
        else
            tmuxinator start dev || {
                echo "Failed to start default tmuxinator project, falling back to tmux-here..." >&2
                tmux-here
            }
        fi
      '';

      ts = ''
        if ! command -v tmux >/dev/null 2>&1; then
            echo "Error: tmux is not installed or not in PATH" >&2
            return 1
        fi

        if ! tmux info &>/dev/null; then
            echo "No tmux server running"
            return 1
        fi

        if [ $# -eq 0 ]; then
            if ! command -v fzf >/dev/null 2>&1; then
                echo "Available sessions:"
                tmux list-sessions -F '#S'
                echo "Use 'ts <session_name>' to switch"
                return 0
            fi

            local session
            session=$(tmux list-sessions -F '#S' 2>/dev/null | fzf --reverse --preview='tmux capture-pane -p -t {} 2>/dev/null || echo "No preview available"')

            if [ -n "$session" ]; then
                if [ -n "$TMUX" ]; then
                    tmux switch-client -t "$session"
                else
                    tmux attach-session -t "$session"
                fi
            fi
        else
            if tmux has-session -t "$1" 2>/dev/null; then
                if [ -n "$TMUX" ]; then
                    tmux switch-client -t "$1"
                else
                    tmux attach-session -t "$1"
                fi
            else
                echo "Session '$1' does not exist" >&2
                return 1
            fi
        fi
      '';

      refresh-env = ''
        unset __HM_SESS_VARS_SOURCED
        source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
        echo "Environment refreshed from Home Manager"
      '';
    };

    initContent = ''
      [[ ! $(command -v nix) && -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]] && source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'

      source $XDG_CONFIG_HOME/bash/secrets

      source <(fzf --zsh)
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [
        "zsh-syntax-highlighting"
        "zsh-autosuggestions"
        "fzf-tab"
      ];
      theme = "";
      custom = config.home.homeDirectory + "/.oh-my-zsh/custom";
    };

    shellAliases = {
      config = "$XDG_CONFIG_HOME";
      g = "git";
      gcd = "$(git rev-parse --show-toplevel)";
      hm = "home-manager switch --flake ~/.config/nix";
      home-manager = "home-manager switch --flake ~/.config/nix";
      l = "eza --hyperlink";
      ll = "eza --header --all --long --git --color=always --icons=auto --hyperlink";
      lt = "eza --tree --all --level 3 --hyperlink";

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

    history.size = 100000;
  };
}
