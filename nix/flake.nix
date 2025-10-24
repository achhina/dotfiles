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
          modules = [
            ./home-manager/home.nix
          ];
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          inherit modules;
        };
    in {
      homeConfigurations.achhina = mkHomeConfiguration (builtins.currentSystem or "x86_64-darwin");
      # Alias for backward compatibility
      homeConfigurations.default = mkHomeConfiguration (builtins.currentSystem or "x86_64-darwin");

      # Development shells for different project types
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        import ./modules/devshells.nix { inherit pkgs; });
    };
}
