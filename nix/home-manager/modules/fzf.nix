{ config, pkgs, ... }:

{
  programs.fzf = {
    enable = true;

    # Use fd for faster, more intelligent searching
    defaultCommand = "fd --type f --hidden --follow --exclude .git";

    # Enhanced default options
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
      "--preview-window=:hidden"
      "--bind=ctrl-/:toggle-preview"
    ];

    # File widget (CTRL-T) with preview
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
    ];

    # Directory widget (ALT-C) with tree preview
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'eza --tree --level=2 --color=always {}'"
    ];

    # History widget (CTRL-R) improvements
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];

    # Gruvbox-inspired colors matching your theme
    colors = {
      fg = "#ebdbb2";
      bg = "#282828";
      hl = "#fabd2f";
      "fg+" = "#ebdbb2";
      "bg+" = "#3c3836";
      "hl+" = "#fabd2f";
      info = "#83a598";
      prompt = "#bdae93";
      spinner = "#fabd2f";
      pointer = "#83a598";
      marker = "#fe8019";
      header = "#665c54";
    };

    # Shell integrations
    enableZshIntegration = true;
    enableBashIntegration = true;
  };
}
