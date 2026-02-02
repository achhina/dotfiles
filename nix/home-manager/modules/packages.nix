{ pkgs, lib, ... }:

let
  # Override arrays - modify these for work/local-specific changes
  # git rerere will learn to auto-resolve conflicts in this section
  overrideAdd = with pkgs; [
    # Add work-specific packages here
  ];

  overrideRemove = [
    # Add package names to remove here (use pname, e.g., "obsidian")
  ];

  # Helper to get package name from a package or derivation
  getPkgName = pkg:
    if builtins.isString pkg then pkg
    else if pkg ? pname then pkg.pname
    else if pkg ? name then pkg.name
    else builtins.trace "Warning: Cannot determine package name for ${toString pkg}" "";

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
    # @upstream-issue: https://github.com/NixOS/nixpkgs/issues/483584
    # pre-commit - removed temporarily due to Swift 5.10.1/clang 21 build issues
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
    nil                              # Nix LSP (used for nix evaluation)
    pyright                          # Python LSP (provides pyright-langserver)
    just-lsp                         # Just LSP (justfile language server)
    nginx-language-server            # Nginx configuration LSP
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

    # Rust
    rustup
    (lib.hiPrio cargo)
    (lib.hiPrio rustc)
    (lib.hiPrio rustfmt)
    (lib.hiPrio clippy)
    (lib.hiPrio rust-analyzer)

    # JavaScript/TypeScript
    nodejs                   # Node.js runtime
    yarn                     # Package manager

    # Lua
    lua                      # Lua interpreter
    luaPackages.luacheck     # Lua static analyzer
    luaPackages.luarocks     # Lua package manager

    # Python
    # @upstream-issue: https://github.com/ipython/ipython/issues/14532
    python312Packages.black                      # Code formatter for IPython (ruff workaround)
    python312Packages.ipython                    # Enhanced Python REPL
    uv                                           # Fast Python package manager
    python312Packages.copier                     # Project templating tool
  ];

  # Document processing and generation tools
  documentTools = with pkgs; [
    # @upstream-issue: https://github.com/NixOS/nixpkgs/issues/335148
    # Wrap mermaid-cli to use Chrome for puppeteer (missing dependencies workaround)
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
  ];

  # Cross-platform GUI applications
  guiApps = with pkgs; [
    obsidian                 # Knowledge base on local Markdown files
    qbittorrent              # Feature-rich BitTorrent client
    zotero                   # Research paper and reference manager
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
    # @upstream-issue: https://github.com/NixOS/nixpkgs/issues/450042
    firefox              # Web browser (builds on Linux, gtk+3 build fails on macOS)
    firefoxpwa           # Progressive Web Apps for Firefox
    alacritty            # GPU-accelerated terminal emulator
    isd                  # TUI to interactively work with systemd units
    signal-desktop       # Private messaging app
  ];
  # Combine base packages
  basePackages =
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

  # Apply overrides: filter out removed packages, add new ones
  finalPackages =
    (builtins.filter
      (pkg: !(builtins.elem (getPkgName pkg) overrideRemove))
      basePackages)
    ++ overrideAdd;
in
{
  home.packages = finalPackages;
}
