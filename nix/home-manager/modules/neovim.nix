{ pkgs, ... }:

let
  # Pin bash-language-server to working version
  oldPkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/fa0ef8a6bb1651aa26c939aeb51b5f499e86b0ec.tar.gz";
    sha256 = "sha256:2Kp9St3Pbsmu+xMsobLcgzzUxPvZR7alVJWyuk2BAPc=";
  }) { system = pkgs.system; };
in
{
  programs.neovim = {
    enable = true;

    # Python packages for Neovim
    extraPython3Packages = ps: with ps; [
      debugpy  # Python debugger for nvim-dap-python
    ];

    # LSP servers and tools available only within Neovim
    extraPackages = with pkgs; [
      # Editor-only LSPs
      oldPkgs.bash-language-server
      lua-language-server
      pyright
      typescript-language-server
      yaml-language-server
      dockerfile-language-server
      marksman
      taplo
      vscode-langservers-extracted
      clang-tools              # Provides clangd LSP for C/C++

      # Neovim-specific tools
      tree-sitter              # Syntax highlighting parser
      chafa                    # Image viewer for fzf-lua preview
      imagemagick              # Image processing for Snacks.image
      ghostscript              # PostScript/PDF interpreter for PDF rendering
    ];
  };
}
