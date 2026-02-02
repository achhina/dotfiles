{
  description = "Dotfiles repository development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        devShells.default = pkgs.mkShell {
          name = "dotfiles-dev";

          buildInputs = with pkgs; [
            prek
          ];

          shellHook = ''
            echo "🔧 Dotfiles development environment loaded"
            echo "📁 Repository: $(pwd)"
            echo "🏠 Home Manager flake: ./nix/flake.nix"
            echo ""
            echo "Available commands:"
            echo "  hm switch    - Apply Home Manager configuration"
            echo "  nix flake update - Update flake inputs"
            echo "  nix develop ./nix# - Enter Home Manager devshells"
          '';
        };
      }
    );
}
