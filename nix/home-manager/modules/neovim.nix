{ pkgs, lib, ... }:

let
  # Pin bash-language-server to working version
  oldPkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/fa0ef8a6bb1651aa26c939aeb51b5f499e86b0ec.tar.gz";
    sha256 = "sha256:2Kp9St3Pbsmu+xMsobLcgzzUxPvZR7alVJWyuk2BAPc=";
  }) { system = pkgs.stdenv.hostPlatform.system; };

  # Architecture detection for Intel-specific workarounds
  isIntelDarwin = pkgs.stdenv.system == "x86_64-darwin";
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # Python packages for Neovim
    extraPython3Packages = ps: with ps; [
      debugpy  # Python debugger for nvim-dap-python
    ];

    # LSP servers and tools available only within Neovim
    extraPackages = with pkgs; [
      # Editor-only LSPs
      lua-language-server
      basedpyright
      typescript-language-server
      yaml-language-server
      dockerfile-language-server
      marksman
      taplo
      vscode-langservers-extracted
      clang-tools              # Provides clangd LSP for C/C++

      # Neovim-specific tools
      nodejs                   # Required for Copilot.lua (must be >= 22)
      tree-sitter              # Syntax highlighting parser
      chafa                    # Image viewer for fzf-lua preview
      imagemagick              # Image processing for Snacks.image
      ghostscript              # PostScript/PDF interpreter for PDF rendering
      pkgs.texlivePackages.detex  # LaTeX to plain text for render-markdown plugin
      pkgs.tectonic            # LaTeX engine for document compilation
      pkgs.lazygit             # Terminal UI for Git (for Snacks.lazygit)
    ] ++ [
      # Pin to older nixpkgs on Intel macOS to avoid build failures
      # Use current nixpkgs on Apple Silicon and other platforms
      (if isIntelDarwin then oldPkgs.bash-language-server else pkgs.bash-language-server)
      (if isIntelDarwin then oldPkgs.vscode-js-debug else pkgs.vscode-js-debug)
    ];
  };
}
