{ pkgs, pkgs-bat-extras, config, ... }:

let
  cfg = config.programs.tmux;
  prefix = if cfg.prefix != null then cfg.prefix else "C-${cfg.shortcut}";
  theme = config.theme.colors;
  icons = config.theme.icons;
  separators = config.theme.separators;

  # Separator definitions
  sep_bar = "#[fg=${theme.grey},bg=${theme.bg0}]${separators.bar}";

  # Double separator effect at edges
  sep_left_end1 = "#[fg=${theme.bg0},bg=${theme.bg2}]${separators.right}";
  sep_left_end2 = "#[fg=${theme.bg2},bg=${theme.bg0}]${separators.right}";

  sep_right_edge1 = "#[fg=${theme.bg2},bg=${theme.bg0}]${separators.left}";
  sep_right_edge2 = "#[fg=${theme.bg0},bg=${theme.bg2}]${separators.left}";

  # Widget definitions
  widget_host = "#[fg=${theme.purple},bg=${theme.bg0}]${icons.host} #[fg=${theme.fg}]#H ";
  widget_session = "#[fg=${theme.blue},bg=${theme.bg0}]${icons.session} #S ";
  widget_network = "#[fg=${theme.green},bg=${theme.bg0}]${icons.network} #[fg=${theme.fg}]#(~/.config/tmux/scripts/network.sh) ";
  widget_cpu = "#[fg=${theme.red},bg=${theme.bg0}]${icons.cpu} #[fg=${theme.fg}]#(tmux-mem-cpu-load -v) ";
  widget_battery = "#[fg=${theme.green},bg=${theme.bg0}]#{battery_icon_status} #[fg=${theme.fg}]#{battery_percentage} ";
  widget_clock = "#[fg=${theme.blue},bg=${theme.bg0}]${icons.clock} #[fg=${theme.fg}]%H:%M ";
in
{
  # Tmuxinator project templates
  xdg.configFile."tmuxinator/dev.yml".text = ''
    name: <%= @args[0] || File.basename(ENV['PWD']).gsub(/^\./, 'dot') %>
    root: <%= @args[1] || ENV['PWD'] %>
    startup_window: editor
    windows:
      - editor:
          layout: main-vertical
          panes:
            - nvim +'SetupTestTab'
            - # terminal for commands
  '';

  xdg.configFile."tmuxinator/fullstack.yml".text = ''
    name: <%= @args[0] || File.basename(ENV['PWD']).gsub(/^\./, 'dot') %>
    root: <%= @args[1] || ENV['PWD'] %>
    startup_window: frontend
    windows:
      - frontend:
          layout: main-vertical
          panes:
            - nvim
            - npm start
            - npm test
      - backend:
          layout: main-vertical
          panes:
            - nvim
            - # server commands
            - # database/api tools
      - monitoring:
          layout: even-horizontal
          panes:
            - htop
            - tail -f logs/app.log
  '';

  xdg.configFile."tmuxinator/research.yml".text = ''
    name: <%= @args[0] || File.basename(ENV['PWD']).gsub(/^\./, 'dot') %>
    root: <%= @args[1] || ENV['PWD'] %>
    startup_window: main
    windows:
      - main:
          layout: even-horizontal
          panes:
            - nvim
            - # documentation/web browsing
      - repl:
          layout: even-vertical
          panes:
            - # language REPL/console
            - # testing/experiments
      - notes:
          panes:
            - nvim notes.md
  '';

  xdg.configFile."tmuxinator/dynamic.yml".text = ''
    name: <%= @settings['name'] || @args[0] || File.basename(ENV['PWD']).gsub(/^\./, 'dot') %>
    root: <%= @settings['path'] || @args[1] || ENV['PWD'] %>
    startup_window: <%= @settings['startup'] || 'main' %>
    windows:
      - main:
          layout: <%= @settings['layout'] || 'main-vertical' %>
          panes:
            - <%= @settings['editor'] || 'nvim' %>
            - # <%= @settings['command'] || 'terminal' %>
      - server:
          panes:
            - # <%= @settings['server'] || 'server commands' %>
      - monitor:
          panes:
            - <%= @settings['monitor'] || 'htop' %>
  '';

  # Tmux scripts
  xdg.configFile."tmux/scripts/network.sh" = {
    text = ''
      #!/bin/bash
      # Get network rates by sampling twice with 1 second interval
      line1=$(/usr/sbin/netstat -b -I en0 | tail -1)
      ibytes1=$(echo "$line1" | awk '{print $7}')
      obytes1=$(echo "$line1" | awk '{print $10}')

      sleep 1

      line2=$(/usr/sbin/netstat -b -I en0 | tail -1)
      ibytes2=$(echo "$line2" | awk '{print $7}')
      obytes2=$(echo "$line2" | awk '{print $10}')

      # Calculate rates (bytes per second)
      irate=$((ibytes2 - ibytes1))
      orate=$((obytes2 - obytes1))

      # Format output with fixed width (always show KB/s or higher)
      if [ $irate -ge 1000000 ]; then
          down=$(printf "%4.1fM/s" "$(echo "scale=1; $irate/1000000" | bc)")
      else
          down=$(printf "%4.0fK/s" $((irate/1024)))
      fi

      if [ $orate -ge 1000000 ]; then
          up=$(printf "%4.1fM/s" "$(echo "scale=1; $orate/1000000" | bc)")
      else
          up=$(printf "%4.0fK/s" $((orate/1024)))
      fi

      printf "%s ↓ %s ↑" "$down" "$up"
    '';
    executable = true;
  };



  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    shell = "${pkgs.zsh}/bin/zsh";
    prefix = "C-a";
    mouse = true;
    escapeTime = 10;
    historyLimit = 100000;
    disableConfirmationPrompt = true;
    keyMode = "vi";
    tmuxinator.enable = true;

    extraConfig = ''
      # Spawn interactive non-login shells (prevents .zprofile from running)
      # Follows expert consensus: romkatv, Nick Janetakis
      # See: https://nickjanetakis.com/blog/prevent-tmux-from-starting-a-login-shell-by-default
      set -g default-command "${pkgs.zsh}/bin/zsh"

      # Override Home Manager's tmux prefix binding to restore standard behavior
      # Home Manager PR #7549 added the `-n` flag to the send-prefix binding,
      # which changed the behavior from the tmux default. We want prefix-prefix
      # to send a literal prefix key to the application (standard tmux double-prefix behavior).
      # See: https://github.com/nix-community/home-manager/pull/7549
      unbind -n ${prefix}
      bind ${prefix} send-prefix

      # Automatically renumber windows when one is closed
      set-option -g renumber-windows on

      # Layout configuration
      set -g main-pane-width 67%

      # Update environment variables when attaching to sessions
      set-option -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY PATH LANG LC_ALL LC_CTYPE"

      # Override ~/.tmux/plugins
      setenv -g TMUX_PLUGIN_MANAGER_PATH "$XDG_CONFIG_HOME/tmux/plugins/"

      # Improve plugin reliability and performance
      set -g status-interval 2
      set -g status-right-length 150




      # visual mode with v
      bind-key -T copy-mode-vi v send-keys -X begin-selection

      # Source tmux config
      unbind r
      bind r source-file $XDG_CONFIG_HOME/tmux/tmux.conf

      # Refresh environment variables (Prefix + R)
      bind R send-keys 'refresh-env' Enter

      # Uses VISUAL/EDITOR to determine key bindings but you can't use Esc to exit
      # out of tmux command prompt because escape is mapped to switch mode
      # https://github.com/tmux/tmux/issues/2426#issuecomment-711068362
      set-option -g status-keys emacs
      bind-key -T copy-mode-vi Escape send-keys -X cancel

      # Open up scratch pad
      bind-key -n M-g if-shell -F '#{==:#{session_name},popup}' {
          set-option -t popup status off
          detach-client
      } {
          display-popup -E "tmux new -A -s popup -t popup"
      }

      # Status bar position and update interval
      set-option -g status-position top
      set-option -g status-interval 2

      # Optimize nvim
      set-option -g focus-events on
      set-option -as terminal-overrides ",xterm-256color:RGB"

      # Enable comprehensive terminal features for Ghostty
      set-option -as terminal-features ",*:hyperlinks"      # OSC 8 clickable links
      set-option -as terminal-features ",*:osc7"            # working directory reporting
      set-option -as terminal-features ",*:sync"            # synchronized updates
      set-option -as terminal-features ",*:extkeys"         # extended keyboard protocol
      set-option -as terminal-features ",*:RGB"             # 24-bit truecolor
      set-option -as terminal-features ",*:strikethrough"   # strikethrough text
      set-option -as terminal-features ",*:overline"        # overline text
      set-option -as terminal-features ",*:usstyle"         # underscore styling
      set-option -as terminal-features ",*:256"             # 256 color support
      set-option -as terminal-features ",*:clipboard"       # system clipboard
      set-option -as terminal-features ",*:ccolour"         # cursor color setting
      set-option -as terminal-features ",*:cstyle"          # cursor style setting
      set-option -as terminal-features ",*:focus"           # focus reporting
      set-option -as terminal-features ",*:mouse"           # mouse support
      set-option -as terminal-features ",*:title"           # window title setting
      set-option -as terminal-features ",*:margins"         # DECSLRM margin support
      set-option -as terminal-features ",*:rectfill"        # DECFRA rectangle fill

      # Bell notifications for Ghostty
      set -g allow-passthrough on
      set -g bell-action any
      set -g monitor-bell on
      set -g visual-bell off

      # Remove tmux-copycat plugin and just use tmux regex search
      bind-key / copy-mode \; send-keys ?

      # Override tmux-pain-control
      # <Prefix-l> to clear screen
      bind l send-keys 'C-l'

      # Quick layout switching
      bind H select-layout even-horizontal
      bind V select-layout even-vertical
      bind M select-layout main-vertical
      bind m select-layout main-horizontal
      bind T select-layout tiled

      # FZF session picker (replaces default sessionist Prefix+g)
      bind g display-popup -E "tmux list-sessions | sed -E 's/:.*$//' | grep -v \"^$(tmux display-message -p '#S')\$\" | fzf --reverse --preview='tmux capture-pane -p -t {}' | xargs tmux switch-client -t"

      # Enhanced choose-tree with better formatting
      bind s choose-tree -Zs -O time -f '#{?pane_format,#{pane_current_command},#{?window_format,#{window_name},#{session_name}}}'

      set -g status-style "bg=${theme.ui.fill.bg},fg=${theme.ui.fill.fg}"
      set -g window-status-style "fg=${theme.ui.inactive.fg},bg=${theme.ui.fill.bg}"
      set -g window-status-current-style "fg=${theme.ui.active.fg},bg=${theme.ui.active.bg}"
      set -g pane-border-style "fg=${theme.bg3}"
      set -g pane-active-border-style "fg=${theme.ui.active.bg}"
      set -g message-style "fg=${theme.fg},bg=${theme.bg2}"
      set -g message-command-style "fg=${theme.fg},bg=${theme.bg2}"

      set -g status-left-length 150
      set -g status-right-length 150

      set -g status-left "${widget_host}${sep_bar}${widget_session}${sep_bar}${widget_network}${sep_left_end1}${sep_left_end2}"

      set -g status-justify centre
      set -g window-status-format " #[fg=${theme.ui.inactive.fg}]${icons.window} #I "
      set -g window-status-current-format " #[fg=${theme.ui.active.fg}]${icons.window} #I#[fg=${theme.bg3}]:#[fg=${theme.ui.active.fg}]#W "

    '';

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = vim-tmux-navigator;
        extraConfig = "";
      }
      {
        plugin = yank;
        extraConfig = "";
      }
      {
        plugin = open;
        extraConfig = ''
          set -g @open-S 'https://www.google.com/search?q='
        '';
      }
      {
        plugin = sessionist;
        extraConfig = "";
      }
      {
        plugin = pain-control;
        extraConfig = "";
      }
      {
        plugin = pkgs.tmuxPlugins.battery;
        extraConfig = ''
          set -g @batt_icon_status_charging '${icons.battery_charging}'
          set -g @batt_icon_status_discharging '${icons.battery_discharging}'
          set -g @batt_icon_status_attached '${icons.battery_full}'
          set -g @batt_icon_status_unknown '${icons.battery_unknown}'

          set -g status-right "${sep_right_edge1}${sep_right_edge2}${widget_cpu}${sep_bar}${widget_battery}${sep_bar}${widget_clock}"
        '';
      }
      {
        plugin = fzf-tmux-url;
        extraConfig = ''
          set -g @fzf-url-bind 'u'
        '';
      }
      {
        # @upstream-issue: Pinned to older nixpkgs due to llvm/crystal build failure in tmux-fingers dependency
        # Current nixpkgs (eb8d947, 2026-02-01) has llvm 22.1.0-rc2 test failures:
        # FAILED: CMakeFiles/check-all (1 of 72511 tests failed)
        # This blocks crystal 1.19.1 build, which blocks tmux-fingers 2.5.1
        # Related: https://github.com/NixOS/nixpkgs/issues/395168 (LLVM ppc64le build failure)
        # TODO: Monitor nixpkgs-unstable and remove pinning when fixed
        plugin = pkgs-bat-extras.tmuxPlugins.fingers;
        extraConfig = ''
          # tmux-fingers configuration
          set -g @fingers-key f
        '';
      }
      # Session management plugins (last)
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-processes '"~nvim->nvim" "~claude->claude -c"'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
        '';
      }
    ];
  };
}
