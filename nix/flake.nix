{
  description = "Home Manager configuration";

  nixConfig = {
    extra-substituters = [ "https://cache.nixos.org/" ];
    extra-trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    allow-unfree = true;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Pinned for bat-extras due to nushell build failure
    nixpkgs-bat-extras.url = "github:NixOS/nixpkgs/6308c3b21396534d8aaeac46179c14c439a89b8a";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-bat-extras, home-manager }:
    let
      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      mkHomeConfiguration = system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          modules = [
            ./home-manager/home.nix
            {
              # Make pinned nixpkgs available to modules
              _module.args.pkgs-bat-extras = import nixpkgs-bat-extras {
                inherit system;
                config.allowUnfree = true;
              };
            }
          ];
        };
    in {
      homeConfigurations = forAllSystems (system:
        mkHomeConfiguration system
      );

      devShells = forAllSystems (system:
        import ./modules/devshells.nix {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        });
    };
}
