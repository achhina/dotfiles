{ config, pkgs, ... }:

{
  home.packages =
    with pkgs;
    [
      # Cross-platform packages
      aichat
      bash-language-server
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
      git
      git-lfs
      github-cli
      gopls # Go LSP
      htop
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
      rust-analyzer # Rust LSP
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
      yarn
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
