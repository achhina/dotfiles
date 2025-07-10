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
          set -g status-right-length 150
          set -g status-left-length 150
          set -g status-left "#{E:@catppuccin_status_host}"
          set -ag status-left "#{E:@catppuccin_status_session}"
          set -ag status-left "#[fg=#94e2d5]#[fg=#11111b,bg=#94e2d5]󰖩 #[fg=#cdd6f4,bg=#313244] #(~/.config/tmux/scripts/network.sh) #[fg=#313244]#{@catppuccin_status_right_separator}"
          set -g status-right "#[fg=#89b4fa]#[fg=#11111b,bg=#89b4fa]󰊚 #[fg=#cdd6f4,bg=#313244] #(tmux-mem-cpu-load --interval 2 --graph-lines 5 --mem-mode 0 --colors) #[fg=#313244]#{@catppuccin_status_right_separator}"
          set -ag status-right "#{E:@catppuccin_status_date_time}"
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
