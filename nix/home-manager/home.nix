{ config, pkgs, ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/git.nix
    ./modules/shell.nix
    ./modules/aerospace.nix
    ./modules/tmux.nix
    ./modules/tridactyl.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "achhina";
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # Environment variables
  home.sessionVariables = {
    EZA_COLORS = "gm=33:ga=31";
    VISUAL = "nvim";
    EDITOR = "nvim";
    XDG_HOME = config.home.homeDirectory;
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";
    XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
    XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
    IPYTHONDIR = "${config.home.homeDirectory}/.config/ipython";
    JUPYTER_CONFIG_DIR = "${config.home.homeDirectory}/.config/jupyter";
  };

  # Configure Nix settings
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
