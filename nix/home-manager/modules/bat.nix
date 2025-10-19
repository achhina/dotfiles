{ pkgs, ... }:

{
  programs.bat = {
    enable = true;

    config = {
      # Theme matching git delta configuration
      theme = "TwoDark";

      pager = "less -FR";

      style = "numbers,changes,header";

      # Custom syntax mappings for common files
      map-syntax = [
        ".ignore:Git Ignore"
        ".gitignore:Git Ignore"
        ".fdignore:Git Ignore"
        "*.conf:INI"
        "Dockerfile*:Dockerfile"
        "docker-compose*:YAML"
        ".env*:Bash"
      ];
    };

    extraPackages = with pkgs.bat-extras; [
      batdiff
      batman
      batgrep
      batwatch
    ];
  };
}
