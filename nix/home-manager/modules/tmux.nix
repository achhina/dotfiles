{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    prefix = "C-a";
    mouse = true;
    escapeTime = 10;

    extraConfig = ''
      # Override ~/.tmux/plugins
      setenv -g TMUX_PLUGIN_MANAGER_PATH "$XDG_CONFIG_HOME/tmux/plugins/"

      # visual mode with v
      bind-key -T copy-mode-vi v send-keys -X begin-selection

      # Source tmux config
      unbind r
      bind r source-file $XDG_CONFIG_HOME/tmux/tmux.conf

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
          display-popup -E "tmux new -A -s popup -t aichat"
      }

      # Status bar position and update interval
      set-option -g status-position top
      set-option -g status-interval 2

      # Optimize nvim
      set-option -g focus-events on
      set-option -as terminal-overrides ",xterm-256color:RGB"

      # Remove tmux-copycat plugin and just use tmux regex search
      bind-key / copy-mode \; send-key ?

      # Override tmux-pain-control
      # <Prefix-l> to clear screen
      bind l send-keys 'C-l'

      # Configure statusline after catppuccin is loaded
      set -g status-right-length 150
      set -g status-left-length 150

      # Configure statusline using proper catppuccin modules
      set -g status-left "#{E:@catppuccin_status_host}"
      set -ag status-left "#{E:@catppuccin_status_session}"

      # Custom network module (manual styling since catppuccin doesn't have network module)
      set -ag status-left "#[fg=#{@thm_teal}]#{@catppuccin_status_left_separator}#[fg=#{@thm_crust},bg=#{@thm_teal}]󰖩 #[fg=#{@thm_teal},bg=#{@thm_surface_0}] #[fg=#{@thm_fg},bg=#{@thm_surface_0}]#(~/.config/tmux/scripts/network.sh) #[fg=#{@thm_surface_0}]"

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

      # Build statusline
      set -g status-right "#{E:@catppuccin_status_cpu}"
      set -ag status-right "#{E:@catppuccin_status_date_time}"

      # Center windows and show only window number (override catppuccin)
      set -g status-justify centre
      set -g window-status-format "#[fg=#11111b,bg=#{@thm_overlay_2}]#[fg=#181825,reverse]#[none] #I #[fg=#181825,reverse]#[none]"
      set -g window-status-current-format "#[fg=#11111b,bg=#{@thm_mauve}]#[fg=#181825,reverse]#[none] #I #[fg=#181825,reverse]#[none]"
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
        '';
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurect-processes 'nvim'
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
