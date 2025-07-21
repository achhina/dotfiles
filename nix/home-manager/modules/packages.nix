{ pkgs, ... }:

let
  # Pin bash-language-server to working version
  oldPkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/fa0ef8a6bb1651aa26c939aeb51b5f499e86b0ec.tar.gz";
    sha256 = "sha256:2Kp9St3Pbsmu+xMsobLcgzzUxPvZR7alVJWyuk2BAPc=";
  }) { system = pkgs.system; };
in
{
  home.packages =
    with pkgs;
    [
      # Cross-platform packages
      aichat
      oldPkgs.bash-language-server # Pinned to working version
      bandwhich
      bat
      chafa # Image preview for fzf-lua
      clang-tools # provides clangd
      claude-code
      cloc
      delta
      dust
      eza
      fd
      fzf
      gemini-cli
      tmux-mem-cpu-load
      git
      git-lfs
      go
      gopls # Go LSP
      htop
      ifstat-legacy
      jq
      lua
      luaPackages.luacheck
      luaPackages.luarocks
      lua-language-server
      mermaid-cli
      ncdu
      nginx
      nil
      nixpkgs-fmt
      pyright # Python LSP
      python312Packages.black # Python formatter for IPython autoformatter
      python312Packages.ipython # Enhanced Python REPL
      ruff # Python linter/formatter
      rust-analyzer # Rust LSP
      shellcheck # Shell script linter
      marksman # Markdown LSP
      yaml-language-server # YAML LSP
      dockerfile-language-server-nodejs # Docker LSP
      taplo # TOML LSP
      neovim
      nodejs
      pnpm
      pre-commit
      ripgrep
      stylua
      starship
      tectonic
      texlivePackages.detex # LaTeX support for render-markdown
      tree-sitter # CLI for installing treesitter parsers
      tldr
      tmux
      typescript
      typescript-language-server
      uv
      vscode-langservers-extracted
      wget
      yamllint
      yarn

      # GitHub CLI extensions
      gh-dash # Interactive dashboard for PRs and issues
      gh-copilot # AI-powered command suggestions
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
      # macOS-specific packages
      aerospace
      iterm2
      jankyborders
      keycastr
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
      # Linux-specific packages
      firefox
      alacritty
    ];
}
