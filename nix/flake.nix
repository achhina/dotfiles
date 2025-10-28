{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/63bdb5d90fa2fa11c42f9716ad1e23565613b07c";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      mkHomeConfiguration = system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          modules = [ ./home-manager/home.nix ];
        };
    in {
      # homeConfigurations naming strategy:
      # - System-based: "aarch64-darwin", "x86_64-darwin", etc. (auto-generated)
      # - User alias: "achhina" (for convenience, points to primary system)
      #
      # Shell aliases (shell.nix) use ${pkgs.system} which automatically resolves
      # to the correct system-based configuration (e.g., "aarch64-darwin").
      #
      # Note: Do NOT use hostname-based configurations (e.g., "MacBook-Pro").
      # Hostnames vary per machine, but system type is consistent and portable.
      homeConfigurations = (forAllSystems (system:
        mkHomeConfiguration system
      )) // {
        # Personal alias for primary development machine
        achhina = mkHomeConfiguration "aarch64-darwin";
      };

      devShells = forAllSystems (system:
        import ./modules/devshells.nix {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        });
    };
}
