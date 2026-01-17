{ pkgs, lib, ... }:

let
  # Platform-specific custom pages directory
  customPagesDir = if pkgs.stdenv.isDarwin
    then "Library/Application Support/tealdeer/pages"
    else ".local/share/tealdeer/pages";

  # Get all custom page files
  customPagesPath = ../files/tealdeer/pages;
in
{
  # Use built-in tealdeer module
  programs.tealdeer = {
    enable = true;
    settings = {
      updates = {
        auto_update = true;
      };
    };
  };

  # Deploy custom tealdeer pages (not supported by built-in module)
  home.file = lib.mkMerge [
    (lib.mapAttrs'
      (name: _:
        lib.nameValuePair
          "${customPagesDir}/${name}"
          { source = "${customPagesPath}/${name}"; }
      )
      (builtins.readDir customPagesPath))
  ];
}
