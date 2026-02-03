{ pkgs, pkgs-bat-extras, ... }:

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

    # @upstream-issue: https://github.com/nushell/nushell/pull/14764
    # Current nixpkgs (eb8d947, 2026-02-01) has nushell 0.110.0 with failing test:
    # shell::environment::env::path_is_a_list_in_repl (I/O error: Operation not permitted)
    # Pinned to older nixpkgs until PATH conversion fix is merged and released
    extraPackages = with pkgs-bat-extras.bat-extras; [
      batdiff
      batman
      batgrep
      batwatch
    ];
  };
}
