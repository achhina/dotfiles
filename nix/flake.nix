{
  description = "Home Manager configuration for achhina";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, mac-app-util }:
    let
      # Automatically detect system architecture
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Function to create home configuration for any system
      mkHomeConfiguration = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          # Only include mac-app-util on Darwin systems
          modules = [
            ./home-manager/home.nix
          ] ++ nixpkgs.lib.optionals (nixpkgs.lib.hasSuffix "darwin" system) [
            mac-app-util.homeManagerModules.default
          ];
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          inherit modules;
        };
    in {
      homeConfigurations.achhina = mkHomeConfiguration (builtins.currentSystem or "x86_64-darwin");
    };
}
