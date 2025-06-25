{ config, pkgs, ... }:

let
  # System detection
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "achhina";
  home.homeDirectory =
    if isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";

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
  home.packages =
    with pkgs;
    [
      # Cross-platform packages
      aichat
      bash-language-server
      bat
      chafa                # Image preview for fzf-lua
      clang-tools          # provides clangd
      claude-code
      cloc
      delta
      dust
      eza
      fd
      fzf
      git
      git-lfs
      github-cli
      gopls               # Go LSP
      htop
      jq
      lua
      luaPackages.luacheck
      luaPackages.luarocks
      lua-language-server
      mermaid-cli
      ncdu
      nginx
      nil
      nixpkgs-fmt
      pyright            # Python LSP
      rust-analyzer      # Rust LSP
      marksman           # Markdown LSP
      yaml-language-server # YAML LSP
      dockerfile-language-server-nodejs # Docker LSP
      taplo              # TOML LSP
      neovim
      nodejs
      pnpm
      pre-commit
      ripgrep
      stylua
      starship
      tectonic
      texlive.combined.scheme-medium # LaTeX support for render-markdown
      tldr
      tmux
      typescript
      typescript-language-server
      uv
      vscode-langservers-extracted
      wget
      yarn
    ]
    ++ pkgs.lib.optionals isDarwin [
      # macOS-specific packages
      aerospace
      iterm2
      jankyborders
      keycastr
    ]
    ++ pkgs.lib.optionals isLinux [
      # Linux-specific packages
      firefox
      alacritty
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

    # ".config/starship.toml".source = ../starship/starship.toml;
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

  # Enable direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.ghostty = pkgs.lib.mkIf isDarwin {
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

  home.file.".config/aerospace/aerospace.toml".text = ''
    after-login-command = []
    after-startup-command = [
        # JankyBorders has a built-in detection of already running process,
        # so it won't be run twice on AeroSpace restart
        'exec-and-forget /Users/achhina/.nix-profile/bin/borders'
    ]
    start-at-login = true

    on-focused-monitor-changed = ['move-mouse monitor-lazy-center']

    default-root-container-layout = 'accordion'
    default-root-container-orientation = 'horizontal'

    # Set same as one used in JankyBorders
    [gaps]
    inner.horizontal = 5
    inner.vertical = 5
    outer.left = 5
    outer.bottom = 5
    outer.top = 5
    outer.right = 5

    [mode.main.binding]
    alt-h = 'focus --boundaries-action wrap-around-the-workspace left'
    alt-j = 'focus --boundaries-action wrap-around-the-workspace down'
    alt-k = 'focus --boundaries-action wrap-around-the-workspace up'
    alt-l = 'focus --boundaries-action wrap-around-the-workspace right'

    alt-shift-h = ['move left', 'mode main']
    alt-shift-j = ['move down', 'mode main']
    alt-shift-k = ['move up', 'mode main']
    alt-shift-l = ['move right', 'mode main']


    alt-minus = 'resize smart -50'
    alt-equal = 'resize smart +50'

    alt-tab = 'workspace-back-and-forth'
    alt-shift-tab = 'move-workspace-to-monitor --wrap-around next'

    alt-f = 'fullscreen'

    alt-slash = 'layout tiles horizontal vertical'
    alt-comma = 'layout accordion horizontal vertical'

    alt-shift-space = 'layout floating accordion' # 'floating toggle' in i3

    # Turn off hide application shortcut
    cmd-h = []
    cmd-alt-h = [] # Disable "hide others"

    alt-1 = 'workspace 1'
    alt-2 = 'workspace 2'
    alt-3 = 'workspace 3'
    alt-4 = 'workspace 4'
    alt-5 = 'workspace 5'
    alt-6 = 'workspace 6'
    alt-7 = 'workspace 7'
    alt-8 = 'workspace 8'
    alt-9 = 'workspace 9'
    alt-0 = 'workspace 10'

    alt-shift-1 = 'move-node-to-workspace 1'
    alt-shift-2 = 'move-node-to-workspace 2'
    alt-shift-3 = 'move-node-to-workspace 3'
    alt-shift-4 = 'move-node-to-workspace 4'
    alt-shift-5 = 'move-node-to-workspace 5'
    alt-shift-6 = 'move-node-to-workspace 6'
    alt-shift-7 = 'move-node-to-workspace 7'
    alt-shift-8 = 'move-node-to-workspace 8'
    alt-shift-9 = 'move-node-to-workspace 9'
    alt-shift-0 = 'move-node-to-workspace 10'

    alt-shift-c = 'reload-config'

    alt-r = 'mode resize'

    [mode.resize.binding]
    h = 'resize width -50'
    j = 'resize height +50'
    k = 'resize height -50'
    l = 'resize width +50'
    r = ['flatten-workspace-tree', 'mode main'] # reset layout
    f = ['layout floating tiling', 'mode main'] # Toggle between floating and tiling layout
    enter = 'mode main'
    esc = 'mode main'


    alt-shift-h = ['join-with left', 'mode resize']
    alt-shift-j = ['join-with down', 'mode resize']
    alt-shift-k = ['join-with up', 'mode resize']
    alt-shift-l = ['join-with right', 'mode resize']

    # Set some common workplaces to secondary monitor
    [workspace-to-monitor-force-assignment]
    4 = 1
    3 = 3

    # Application specific configs

    # Move windows for better workspace hygiene
    [[on-window-detected]]
    if.app-id = 'org.mozilla.firefox'
    check-further-callbacks = true
    run = ['move-node-to-workspace 1']

    [[on-window-detected]]
    if.app-id = 'com.googlecode.iterm2'
    check-further-callbacks = true
    run = ['move-node-to-workspace 2']

    [[on-window-detected]]
    if.app-id = 'com.mitchellh.ghostty'
    check-further-callbacks = true
    run = ['move-node-to-workspace 2']

    [[on-window-detected]]
    if.app-id = 'com.apple.iCal'
    check-further-callbacks = true
    run = ['move-node-to-workspace 3']

    [[on-window-detected]]
    if.app-id = 'com.apple.mail'
    check-further-callbacks = true
    run = ['move-node-to-workspace 3']

    [[on-window-detected]]
    if.app-id = 'com.spotify.client'
    check-further-callbacks = true
    run = ['move-node-to-workspace 4']

    [[on-window-detected]]
    if.app-id = 'md.obsidian'
    check-further-callbacks = true
    run = ['move-node-to-workspace 9']

    [[on-window-detected]]
    if.app-id = 'com.hnc.Discord'
    check-further-callbacks = true
    run = ['move-node-to-workspace 10']

    [[on-window-detected]]
    if.app-id = 'com.apple.MobileSMS'
    check-further-callbacks = true
    run = ['move-node-to-workspace 10']

    [[on-window-detected]]
    if.app-id = 'net.whatsapp.WhatsApp'
    check-further-callbacks = true
    run = ['move-node-to-workspace 10']

    [[on-window-detected]]
    if.app-id = 'com.automattic.beeper.desktop'
    check-further-callbacks = true
    run = ['move-node-to-workspace 10']
  '';

  programs.starship = {
    enable = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = "[](color_orange)$os$username[](bg:color_yellow fg:color_orange)$directory[](fg:color_yellow bg:color_aqua)$git_branch$git_status[](fg:color_blue bg:color_bg3)$docker_context$conda[](fg:color_bg3 bg:color_bg1)$time[ ](fg:color_bg1)$line_break$character";

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
          SUSE = "";
          Raspbian = "󰐿";
          Mint = "󰣭";
          Macos = "󰀵";
          Manjaro = "";
          Linux = "󰌽";
          Gentoo = "󰣨";
          Fedora = "󰣛";
          Alpine = "";
          Amazon = "";
          Android = "";
          Arch = "󰣇";
          Artix = "󰣇";
          EndeavourOS = "";
          CentOS = "";
          Debian = "󰣚";
          Redhat = "󱄛";
          RedHatEnterprise = "󱄛";
          Pop = "";
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
          Downloads = " ";
          Music = "󰝚 ";
          Pictures = " ";
          Developer = "󰲋 ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:color_aqua";
        format = "[[ $symbol $branch ](fg:color_fg0 bg:color_aqua)]($style)";
      };

      git_status = {
        style = "bg:color_aqua";
        format = "[[($all_status$ahead_behind )](fg:color_fg0 bg:color_aqua)]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      c = {
        symbol = " ";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      golang = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      java = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      haskell = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      python = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      docker_context = {
        symbol = "";
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
        format = "[[  $time ](fg:color_fg0 bg:color_bg1)]($style)";
      };

      line_break = {
        disabled = false;
      };

      character = {
        disabled = false;
        success_symbol = "[](bold fg:color_green)";
        error_symbol = "[](bold fg:color_red)";
        vimcmd_symbol = "[](bold fg:color_green)";
        vimcmd_replace_one_symbol = "[](bold fg:color_purple)";
        vimcmd_replace_symbol = "[](bold fg:color_purple)";
        vimcmd_visual_symbol = "[](bold fg:color_yellow)";
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
      update = "home-manager switch --flake ~/.config/nix#achhina";
      v = "nvim";
    };

    history.size = 100000;
  };
}
