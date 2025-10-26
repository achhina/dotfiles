{ pkgs, ... }:

let
  # Pin bash-language-server to working version
  oldPkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/fa0ef8a6bb1651aa26c939aeb51b5f499e86b0ec.tar.gz";
    sha256 = "sha256:2Kp9St3Pbsmu+xMsobLcgzzUxPvZR7alVJWyuk2BAPc=";
  }) { system = pkgs.system; };
  # Core system tools and utilities
  coreTools = with pkgs; [
    git                    # Version control
    git-lfs                # Git Large File Storage
    wget                   # File downloader
    htop                   # System monitor
    ncdu                   # Disk usage analyzer
    ifstat-legacy          # Network interface statistics
    bandwhich              # Network utilization by process
    dust                   # Modern du alternative
    cloc                   # Count lines of code
    pre-commit             # Git pre-commit hooks
  ];


  # Modern CLI alternatives to traditional Unix tools
  modernCLI = with pkgs; [
    bat                    # Modern cat with syntax highlighting
    eza                    # Modern ls replacement
    fd                     # Modern find replacement
    ripgrep                # Fast grep replacement
    fzf                    # Fuzzy finder
    tldr                   # Simplified man pages
    jq                     # JSON processor
    delta                  # Enhanced diff viewer
  ];

  # AI interfaces and productivity tools
  aiTools = with pkgs; [
    # claude-code moved to npm install (see claude.nix activation script)
    claude-monitor         # Real-time Claude Code usage monitor
    gemini-cli             # Google Gemini CLI
  ];

  # Editor and terminal environment
  editorTools = with pkgs; [
    tmux                   # Terminal multiplexer
    tmux-mem-cpu-load      # Tmux system info plugin
    starship               # Cross-shell prompt
  ];

  # Language servers for general use (also used outside editor)
  languageServers = with pkgs; [
    gopls                            # Go LSP (used with go tools)
    rust-analyzer                    # Rust LSP (used with cargo)
    nil                              # Nix LSP (used for nix evaluation)
    docker-credential-helpers        # Docker credential helpers
  ];

  # Code linters and formatters
  formatters = with pkgs; [
    shellcheck               # Shell script linter
    stylua                   # Lua formatter
    yamllint                 # YAML linter
    nixpkgs-fmt              # Nix formatter
    ruff                     # Python linter/formatter
    nodePackages.prettier    # JavaScript/TypeScript/HTML/CSS/JSON formatter
  ];

  # Programming language runtimes and tools
  languageRuntimes = with pkgs; [
    # Go
    go                       # Go compiler and tools

    # JavaScript/TypeScript
    nodejs                   # Node.js runtime
    yarn                     # Package manager

    # Lua
    lua                      # Lua interpreter
    luaPackages.luacheck     # Lua static analyzer
    luaPackages.luarocks     # Lua package manager

    # Python
    python312Packages.black    # Code formatter for IPython (see https://github.com/ipython/ipython/issues/14532 for ruff workaround)
    python312Packages.ipython  # Enhanced Python REPL
    uv                         # Fast Python package manager
  ];

  # Document processing and generation tools
  documentTools = with pkgs; [
    mermaid-cli                # Diagram generation
    vhs                        # Terminal recording tool
  ];

  # System services
  systemServices = with pkgs; [
    nginx                    # Web server
  ];

  # GitHub CLI extensions
  githubExtensions = with pkgs; [
    gh-dash                  # Interactive PR/issue dashboard
    gh-copilot               # AI-powered command suggestions
  ];

  # Container tools
  containerTools = with pkgs; [
    docker                   # Container runtime and CLI
    docker-compose           # Multi-container orchestration
    docker-buildx            # Extended build capabilities
  ];

  # Cross-platform GUI applications
  guiApps = with pkgs; [
    obsidian                 # Knowledge base on local Markdown files
  ];

  # macOS-specific packages
  darwinPackages = with pkgs; [
    aerospace            # Tiling window manager for macOS
    iterm2               # Terminal emulator
    jankyborders         # Window border enhancement for Aerospace
    keycastr             # Keystroke visualizer for presentations
  ];

  # Linux-specific packages
  linuxPackages = with pkgs; [
    firefox              # Web browser
    firefoxpwa           # Progressive Web Apps for Firefox
    alacritty            # GPU-accelerated terminal emulator
    isd                  # TUI to interactively work with systemd units
    signal-desktop       # Private messaging app
  ];
in
{
  home.packages =
    coreTools
    ++ modernCLI
    ++ aiTools
    ++ editorTools
    ++ languageServers
    ++ formatters
    ++ languageRuntimes
    ++ documentTools
    ++ systemServices
    ++ githubExtensions
    ++ containerTools
    ++ guiApps
    ++ pkgs.lib.optionals pkgs.stdenv.isDarwin darwinPackages
    ++ pkgs.lib.optionals pkgs.stdenv.isLinux linuxPackages;
}
