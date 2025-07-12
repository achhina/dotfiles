{ config, pkgs, ... }:

{
  xdg.configFile."tridactyl/tridactylrc".source = ../files/tridactylrc;
}
