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

    # @upstream-issue: Pinned to older nixpkgs due to nushell test failure in bat-extras dependency
    # Current nixpkgs (eb8d947, 2026-02-01) has nushell 0.110.0 with failing test:
    # shell::environment::env::path_is_a_list_in_repl (I/O error: Operation not permitted)
    # Related: https://github.com/nushell/nushell/pull/14764 (PATH conversion to list)
    # TODO: Monitor nixpkgs-unstable and remove pinning when fixed
    extraPackages = with pkgs-bat-extras.bat-extras; [
      batdiff
      batman
      batgrep
      batwatch
    ];
  };
}
