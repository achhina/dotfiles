{
  programs.fzf = {
    enable = true;

    defaultCommand = "fd --type f --hidden --follow --exclude .git";

    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
      "--preview-window=right:50%"
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

    # Tokyo Night/Catppuccin colors matching your theme
    colors = {
      fg = "#c0caf5";
      bg = "#1a1b26";
      hl = "#bb9af7";
      "fg+" = "#c0caf5";
      "bg+" = "#292e42";
      "hl+" = "#bb9af7";
      info = "#7aa2f7";
      prompt = "#7dcfff";
      spinner = "#f7768e";
      pointer = "#f7768e";
      marker = "#9ece6a";
      header = "#565f89";
    };

    # Shell integrations
    enableZshIntegration = true;
    enableBashIntegration = true;
  };
}
