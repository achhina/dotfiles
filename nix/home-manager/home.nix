{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "achhina";
  home.homeDirectory = "/Users/achhina";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    aerospace
    aichat
    bash-language-server
    bat
    claude-code
    cloc
    delta
    dust
    eza
    fd
    # firefoxpwa # not available in platform
    fzf
    # ghostty # marked broken for macos darwin at least
    git
    git-lfs
    github-cli
    htop
    iterm2
    jankyborders
    jq
    keycastr
    lua
    luaPackages.luacheck
    luaPackages.luarocks
    lua-language-server
    mermaid-cli
    ncdu
    nginx
    nil
    nixpkgs-fmt
    neovim
    nodejs
    pnpm
    pre-commit
    ripgrep
    stylua
    starship
    # sublime # not available in platform
    tectonic
    tldr
    tmux
    typescript
    typescript-language-server
    uv
    wget
    yarn
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
    EZA_COLORS = "gm=33:ga=31";
    VISUAL = "nvim";
    EDITOR = "nvim";
    XDG_HOME = config.home.homeDirectory;
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";
    XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
    XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
    IPYTHONDIR = "${config.home.homeDirectory}/.config/ipython";
    JUPYTER_CONFIG_DIR = "${config.home.homeDirectory}/.config/jupyter";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;


  programs.ghostty = {
    enable = false;

    settings = {
      # Theme and font settings
      theme = "catppuccin-mocha";
      fontFamily = "Fira Code";

      # MacOS settings
      macosOptionAsAlt = true;
      macosTitlebarStyle = "hidden";
      macosIcon = "chalkboard";
    };
  };

  programs.starship = {
    enable = true;
    # Configuration written to ~/.config/starship.toml
    settings = pkgs.lib.importTOML ../../starship/starship.toml;
  };



  programs.aerospace = {
    enable = false;

    userSettings = {
      after-startup-command = [
        # JankyBorders has a built-in detection of already running process,
        # so it won't be run twice on AeroSpace restart
        "exec-and-forget /usr/local/opt/borders/bin/borders"
      ];
      start-at-login = true;

      enable-normalization-flatten-containers = false;
      enable-normalization-opposite-orientation-for-nested-containers = false;


      # Set same as one used in JankyBorders
      gaps = {
        inner.horizontal = 5;
        inner.vertical = 5;
        outer.left = 5;
        outer.bottom = 5;
        outer.top = 5;
        outer.right = 5;
      };

      mode.main.binding = {
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        alt-minus = "split horizontal";
        alt-shift-slash = "split vertical";

        alt-tab = "workspace-back-and-forth";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";

        alt-f = "fullscreen";

        alt-s = "layout v_accordion"; # "layout stacking" in i3
        alt-w = "layout h_accordion"; # "layout tabbed" in i3
        alt-e = "layout tiles horizontal vertical"; # "layout toggle split" in i3

        alt-shift-space = "layout floating tiling"; # "floating toggle" in i3

        # Turn off hide application shortcut
        cmd-h = [ ];

        # Not supported, because this command is redundant in AeroSpace mental model.
        # See: https://nikitabobko.github.io/AeroSpace/guide#floating-windows
        #alt-space = "focus toggle_tiling_floating"

        # `focus parent`/`focus child` are not yet supported, and it"s not clear whether they
        # should be supported at all https://github.com/nikitabobko/AeroSpace/issues/5
        # alt-a = "focus parent"

        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";
        alt-0 = "workspace 10";

        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";
        alt-shift-0 = "move-node-to-workspace 10";

        alt-shift-c = "reload-config";

        alt-r = "mode resize";
      };

      mode.resize.binding = {
        h = "resize width -50";
        j = "resize height +50";
        k = "resize height -50";
        l = "resize width +50";
        r = [ "flatten-workspace-tree" "mode main" ]; # reset layout
        f = [ "layout floating tiling" "mode main" ]; # Toggle between floating and tiling layout
        enter = "mode main";
        esc = "mode main";
      };
      # Set some common workplaces to secondary monitor
      workspace-to-monitor-force-assignment = {
        "4" = 1;
        "3" = 3;

        # Application specific configs

        # Move windows for better workspace hygiene
        # on-window-detected = [
        # # {
        #   "if" = {
        #     app-id = "org.mozilla.firefox";
        #   };
        #   check-further-callbacks = true;
        #   run = ["move-node-to-workspace 1"];
        # }
        #
        # {
        # "if".app-id = "com.googlecode.iterm2";
        # check-further-callbacks = true;
        # run = ["move-node-to-workspace 2"];
        # }
        #
        # {
        # "if".app-id = "com.mitchellh.ghostty";
        # check-further-callbacks = true;
        # run = ["move-node-to-workspace 2"];
        # }
        #
        # {
        # "if".app-id = "com.apple.iCal";
        # check-further-callbacks = true;
        # run = ["move-node-to-workspace 3"];
        # }
        #
        # {
        # "if".app-id = "com.apple.mail";
        # check-further-callbacks = true;
        # run = ["move-node-to-workspace 3"];
        # }
        #
        # {
        # "if".app-id = "com.spotify.client";
        # check-further-callbacks = true;
        # run = ["move-node-to-workspace 4"];
        # }
        #
        # {
        # "if".app-id = "md.obsidian";
        # check-further-callbacks = true;
        # run = ["move-node-to-workspace 9"];
        # }
        #
        # {
        # "if".app-id = "com.hnc.Discord";
        # check-further-callbacks = true;
        # run = ["move-node-to-workspace 10"];
        # }
        #
        # {
        # "if".app-id = "com.apple.MobileSMS";
        # check-further-callbacks = true;
        # run = ["move-node-to-workspace 10"];
        # }
        #
        # {
        # "if".app-id = "net.whatsapp.WhatsApp";
        # check-further-callbacks = true;
        # run = ["move-node-to-workspace 10"];
        # }
        #
        # # Set layout to floating for Firefox picture-in-picture
        # # https://github.com/nikitabobko/AeroSpace/issues/246#issuecomment-2182361297
        # {
        # "if".app-id = "org.mozilla.firefox";
        # "if".window-title-regex-substring = "Picture-in-Picture";
        # run = "layout floating";
        # # }
        # ];
      };
    };
  };

  # Not ready to move everything over yet
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
      plugins = [ "zsh-syntax-highlighting" "zsh-autosuggestions" "fzf-tab" ];
      theme = "";
      custom = config.home.homeDirectory + "/.oh-my-zsh/custom";
    };

    shellAliases = {
      config = "$XDG_CONFIG_HOME";
      g = "git";
      gcd = "$(git rev-parse --show-toplevel)";
      l = "eza";
      ll = "eza --header --all --long --git --color=always --icons=auto";
      lt = "eza --tree --all --level 3";
      t = "tmux";
      ta = "tmux attach || tmux new-session";
      update = "home-manager switch --flake ~/.config/nix#achhina";
      v = "nvim";
    };


    history.size = 100000;
  };
}
