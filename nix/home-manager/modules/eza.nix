{ config, pkgs, ... }:

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
    ];

    # Shell integrations
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
