{ pkgs }:

{
  programs.bat = {
    enable = true;

    config = {
      # Theme matching git delta configuration
      theme = "TwoDark";

      # Enhanced pager settings
      pager = "less -FR";

      # Show line numbers by default
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

    # Additional bat utilities
    extraPackages = with pkgs.bat-extras; [
      batdiff # Enhanced diff with syntax highlighting
      batman # Manual pages with syntax highlighting
      batgrep # Search with context and highlighting
      batwatch # Watch files with syntax highlighting
    ];
  };
}
