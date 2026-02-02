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
            # Install nightly Rust via rustup if not already installed
            if ! rustup toolchain list | grep -q nightly; then
              echo "Installing Rust nightly toolchain..."
              rustup toolchain install nightly
            fi
            # Prepend nightly toolchain to PATH to override system rust
            NIGHTLY_BIN="$HOME/.rustup/toolchains/nightly-aarch64-apple-darwin/bin"
            if [ -d "$NIGHTLY_BIN" ]; then
              export PATH="$NIGHTLY_BIN:$PATH"
            fi
          '';
        };
      }
    );
}
