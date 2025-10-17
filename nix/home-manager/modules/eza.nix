{
  programs.eza = {
    enable = true;

    # Enhanced display options
    colors = "always";
    icons = "always";
    git = true;

    # Additional options for better output
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
