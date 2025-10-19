{
  programs.eza = {
    enable = true;

    colors = "always";
    icons = "always";
    git = true;

    extraOptions = [
      "--group-directories-first"
      "--header"
      "--group"
      "--time-style=relative"
      "--hyperlink"
    ];

    # Disable shell integrations to avoid conflicting aliases
    enableBashIntegration = false;
    enableZshIntegration = false;
  };
}
