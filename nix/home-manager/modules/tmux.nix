{ pkgs, config, ... }:

let
  cfg = config.programs.tmux;
  prefix = if cfg.prefix != null then cfg.prefix else "C-${cfg.shortcut}";
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
            - nvim
          panes:
            - # terminal for commands
            - # for running servers/builds
      - logs:
          panes:
            - # for monitoring logs/processes
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

      # Configure statusline after catppuccin is loaded
      set -g status-left-length 150

      # Configure statusline using proper catppuccin modules
      set -g status-left "#{E:@catppuccin_status_host}"
      set -ag status-left "#{E:@catppuccin_status_session}"

      # Custom network module (manual styling since catppuccin doesn't have network module)
      set -ag status-left "#[fg=#{@thm_teal}]#{@catppuccin_status_left_separator}#[fg=#{@thm_crust},bg=#{@thm_teal}]󰖩 #[fg=#{@thm_teal},bg=#{@thm_surface_0}] #[fg=#{@thm_fg},bg=#{@thm_surface_0}]#(~/.config/tmux/scripts/network.sh) #[fg=#{@thm_surface_0}]"



      # Center windows - show only number for inactive, number and title for active (override catppuccin)
      set -g status-justify centre
      set -g window-status-format "#[fg=#11111b,bg=#{@thm_overlay_2}]#[fg=#181825,reverse]#[none] #I #[fg=#181825,reverse]#[none]"
      set -g window-status-current-format "#[fg=#11111b,bg=#{@thm_mauve}]#[fg=#181825,reverse]#[none] #I:#W #[fg=#181825,reverse]#[none]"

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
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour 'mocha'
          set -g @catppuccin_window_status_style "rounded"

          # Use catppuccin CPU module (it exists) with custom colors
          set -g @catppuccin_cpu_text " #(tmux-mem-cpu-load --interval 2 --graph-lines 5 --mem-mode 0)"
          set -g @catppuccin_status_cpu_color "#{@thm_blue}"

          # Fix CPU icon background to use blue instead of yellow
          set -g @catppuccin_cpu_color "#{@thm_blue}"
          set -g @catppuccin_status_cpu_icon_bg "#{@thm_blue}"
          set -g @catppuccin_status_cpu_icon_fg "#{@thm_crust}"

          # Customize CPU data background to match other modules
          set -g @catppuccin_status_cpu_text_bg "#{@thm_surface_0}"
          set -g @catppuccin_status_cpu_text_fg "#{@thm_fg}"

          # Customize CPU load colors to match statusline
          set -g @cpu_low_bg_color "#{@thm_surface_0}"
          set -g @cpu_low_fg_color "#{@thm_fg}"
          set -g @cpu_medium_bg_color "#{@thm_surface_0}"
          set -g @cpu_medium_fg_color "#{@thm_yellow}"
          set -g @cpu_high_bg_color "#{@thm_surface_0}"
          set -g @cpu_high_fg_color "#{@thm_red}"
        '';
      }
      # Functional plugins (after theme, before session management)
      {
        plugin = pkgs.tmuxPlugins.battery;
        extraConfig = ''
          # tmux-battery configuration with nerd font icons
          set -g @batt_icon_status_charging '󰂄'
          set -g @batt_icon_status_discharging '󰁹'
          set -g @batt_icon_status_attached '󰚥'
          set -g @batt_icon_status_unknown '󰂑'

          # Set status-right with battery variables BEFORE plugin runs so it can interpolate them
          set -g status-right "#{E:@catppuccin_status_cpu}"
          set -ag status-right "#[fg=#{@thm_lavender}]#{@catppuccin_status_left_separator}#[fg=#{@thm_crust},bg=#{@thm_lavender}]#{battery_icon_status} #[fg=#{@thm_lavender},bg=#{@thm_surface_0}] #[fg=#{@thm_fg},bg=#{@thm_surface_0}]#{battery_percentage} #[fg=#{@thm_surface_0}]"
        '';
      }
      {
        plugin = fzf-tmux-url;
        extraConfig = ''
          set -g @fzf-url-bind 'u'
        '';
      }
      {
        plugin = fingers;
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
