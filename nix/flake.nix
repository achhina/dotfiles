{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/63bdb5d90fa2fa11c42f9716ad1e23565613b07c";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Don't follow our nixpkgs - uses its own pinned version to avoid SBCL 2.5.7 build failures on macOS
    mac-app-util.url = "github:hraban/mac-app-util";
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
