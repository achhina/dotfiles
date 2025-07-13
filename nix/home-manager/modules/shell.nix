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
    package = null;  # Don't install ghostty, just manage config

    settings = {
      # Theme and font settings
      theme = "catppuccin-mocha";
      fontFamily = "Fira Code";

      # Compromise, because when left on it's harder to autoupdate OS.
      confirm-close-surface = false;
    } // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
      # MacOS settings
      macosOptionAsAlt = true;
      macosTitlebarStyle = "hidden";
      macosIcon = "chalkboard";
    };
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

  # Zsh shell configuration
  programs.zsh = {
    enable = true;

    autocd = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      [[ ! $(command -v nix) && -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]] && source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'

      # set emacs keybindings, otherwise zsh uses $EDITOR keybindings
      bindkey -e

      source $XDG_CONFIG_HOME/bash/secrets

      function man(){
          MAN="/usr/bin/man"
          MANPATHS=("/usr/share/man" "/usr/local/share/man" "/nix/var/nix/profiles/default/share/man" "$XDG_HOME/.nix-profile/share/man")
          if [ -n "$1" ]; then
              $MAN "$@"
              return $?
          else
              fd -tf -tl . "$\{MANPATHS[@]}" | sed "s|.*\/||" | sed "s|\..*||" | fzf --reverse --preview="$MAN {}" | xargs $MAN
              return $?
          fi
      }


      # Function to map `$ <command>` to just `command`. Useful for copying single
      # line commands prefixed with '$'.
      # https://github.com/orgs/community/discussions/35615#discussioncomment-10491333
      function \$ { "$@"; }

      # Session management utilities
      function tmux-clean() {
          local current_session=$(tmux display-message -p '#S' 2>/dev/null)
          local sessions_to_kill=$(tmux list-sessions -F '#S' | grep -v "^$current_session$")

          if [ -z "$sessions_to_kill" ]; then
              echo "No sessions to clean (only current session '$current_session' exists)"
              return 0
          fi

          echo "Killing tmux sessions except current ('$current_session'):"
          echo "$sessions_to_kill" | while read session; do
              echo "  ✗ Killing session: $session"
              tmux kill-session -t "$session"
          done
          echo "Done! Cleaned $(echo "$sessions_to_kill" | wc -l | tr -d ' ') sessions"
      }

      function tmux-here() {
          local session_name=$(basename "$PWD" | tr '.' '_')
          tmux new-session -d -s "$session_name" -c "$PWD" || tmux switch-client -t "$session_name"
      }

      function mux-here() {
          if [ -f ".tmuxinator.yml" ]; then
              tmuxinator start .
          else
              tmuxinator start dev
          fi
      }

      function ts() {
          if [ $# -eq 0 ]; then
              # No arguments - show FZF picker
              local session=$(tmux list-sessions -F '#S' | fzf --reverse --preview='tmux capture-pane -p -t {}')
              [ -n "$session" ] && tmux switch-client -t "$session"
          else
              # With argument - switch directly
              tmux switch-client -t "$1"
          fi
      }


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
      # preview directory's content with eza when completing cd
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
      # custom fzf flags
      # NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
      zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
      # To make fzf-tab follow FZF_DEFAULT_OPTS.
      # NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
      zstyle ':fzf-tab:*' use-fzf-default-opts yes
      # switch group using `<` and `>`
      zstyle ':fzf-tab:*' switch-group '<' '>'
      # use tmux floating pane
      zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

      # Completions
      eval "$(starship init zsh)"
      source <(fzf --zsh)

      FPATH="$HOME/.docker/completions:$FPATH"
      autoload -Uz compinit
      compinit
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
      hm = "home-manager switch --flake ~/.config/nix#achhina";
      home-manager = "home-manager switch --flake ~/.config/nix#achhina";
      l = "eza";
      ll = "eza --header --all --long --git --color=always --icons=auto";
      lt = "eza --tree --all --level 3";
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

      update = "nix-channel --update && nix flake update --flake ~/.config/nix && home-manager switch --flake ~/.config/nix#achhina";
      v = "nvim";
    };

    history.size = 100000;
  };
}
