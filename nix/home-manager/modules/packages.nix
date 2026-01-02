{ pkgs, ... }:

let
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
    bitwarden-cli          # Password manager CLI (bw)
    bws                    # Bitwarden Secrets Manager CLI
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
    just-lsp                         # Just LSP (justfile language server)
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
    # Wrap mermaid-cli to use Chrome for puppeteer
    (pkgs.writeShellScriptBin "mmdc" ''
      ${if pkgs.stdenv.isDarwin then ''
        # On macOS, use Homebrew Chrome (stable path, no GC issues)
        export PUPPETEER_EXECUTABLE_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
      '' else ''
        # On Linux, use Nix Chrome
        export PUPPETEER_EXECUTABLE_PATH="${pkgs.google-chrome}/bin/google-chrome-stable"
      ''}
      exec ${pkgs.mermaid-cli}/bin/mmdc "$@"
    '')
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

  # Cross-platform GUI applications
  guiApps = with pkgs; [
    obsidian                 # Knowledge base on local Markdown files
    qbittorrent              # Feature-rich BitTorrent client
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
    google-chrome        # Web browser (macOS protects app bundles in Nix store from GC)
    firefox              # Web browser (builds on Linux, has gtk+3 issues on macOS)
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
    ++ guiApps
    ++ pkgs.lib.optionals pkgs.stdenv.isDarwin darwinPackages
    ++ pkgs.lib.optionals pkgs.stdenv.isLinux linuxPackages;
}
