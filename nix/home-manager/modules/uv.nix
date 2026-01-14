{ config, lib, pkgs, ... }:

{
  # Enable uv package manager
  programs.uv = {
    enable = true;

    # Configuration written to ~/.config/uv/uv.toml
    settings = {
      # Prefer uv-managed Python installations over system Python
      python-preference = "managed";

      # Allow Python downloads (required for declarative installation)
      python-downloads = "automatic";
    };
  };
}
