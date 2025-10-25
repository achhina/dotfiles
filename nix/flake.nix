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
      # Create a configuration for each system with system name as key
      homeConfigurations = (forAllSystems (system:
        mkHomeConfiguration system
      )) // {
        # Named alias
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
