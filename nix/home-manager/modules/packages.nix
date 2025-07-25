{ pkgs, ... }:

let
  # Shell script for cross-platform notifications with tmux support
  notify-script = pkgs.writeShellScriptBin "notify" ''
    #!/usr/bin/env bash

    # notify - Send desktop notifications with tmux support
    # Usage: notify "title" "body"
    #        notify "single message" (uses "Notification" as title)

    if [[ $# -eq 0 ]]; then
        echo "Usage: notify \"title\" \"body\""
        echo "       notify \"message\" (uses default title)"
        exit 1
    fi

    # Set title and body based on arguments
    if [[ $# -eq 1 ]]; then
        title="Notification"
        body="$1"
    else
        title="$1"
        body="$2"
    fi

    # Send OSC 777 notification sequence
    esc=$'\033'
    if [[ -n "$TMUX" ]]; then
        # Inside tmux: use manual passthrough syntax
        printf "''${esc}Ptmux;''${esc}''${esc}]777;notify;%s;%s''${esc}''${esc}\\''${esc}\\" "$title" "$body"
    else
        # Outside tmux: send directly
        printf "''${esc}]777;notify;%s;%s''${esc}\\" "$title" "$body"
    fi
  '';
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
    aichat                 # AI chat interface
    claude-code            # Claude Code CLI
    gemini-cli             # Google Gemini CLI
  ];

  # Editor and terminal environment
  editorTools = with pkgs; [
    neovim                 # Text editor
    tmux                   # Terminal multiplexer
    tmux-mem-cpu-load      # Tmux system info plugin
    starship               # Cross-shell prompt
    chafa                  # Image viewer for terminal (fzf-lua preview)
  ];

  # Language servers for editor integration
  languageServers = with pkgs; [
    oldPkgs.bash-language-server      # Bash LSP (pinned to working version)
    lua-language-server               # Lua LSP
    pyright                          # Python LSP
    gopls                            # Go LSP
    rust-analyzer                    # Rust LSP
    typescript-language-server       # TypeScript LSP
    nil                              # Nix LSP
    marksman                         # Markdown LSP
    yaml-language-server             # YAML LSP
    dockerfile-language-server-nodejs # Docker LSP
    taplo                            # TOML LSP
    vscode-langservers-extracted     # HTML/CSS/JSON LSP
  ];

  # Code linters and formatters
  formatters = with pkgs; [
    shellcheck               # Shell script linter
    stylua                   # Lua formatter
    yamllint                 # YAML linter
    nixpkgs-fmt              # Nix formatter
    ruff                     # Python linter/formatter
  ];

  # Programming language runtimes and tools
  languageRuntimes = with pkgs; [
    # C/C++
    clang-tools              # Provides clangd LSP

    # Go
    go                       # Go compiler and tools

    # JavaScript/TypeScript
    nodejs                   # Node.js runtime
    typescript               # TypeScript compiler
    pnpm                     # Fast package manager
    yarn                     # Package manager

    # Lua
    lua                      # Lua interpreter
    luaPackages.luacheck     # Lua static analyzer
    luaPackages.luarocks     # Lua package manager
    tree-sitter              # Syntax highlighting parser

    # Python
    python312Packages.black    # Code formatter for IPython
    python312Packages.ipython  # Enhanced Python REPL
    uv                         # Fast Python package manager
  ];

  # Document processing and generation tools
  documentTools = with pkgs; [
    tectonic                   # LaTeX engine
    texlivePackages.detex      # LaTeX to plain text (render-markdown)
    mermaid-cli                # Diagram generation
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
    alacritty            # GPU-accelerated terminal emulator
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
    ++ [ notify-script ]  # Custom notification script
    ++ pkgs.lib.optionals pkgs.stdenv.isDarwin darwinPackages
    ++ pkgs.lib.optionals pkgs.stdenv.isLinux linuxPackages;
}
