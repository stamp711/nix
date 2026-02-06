{ config, pkgs, ... }:
{
  home.stateVersion = "26.05";

  nix.package = pkgs.nix;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  xdg.enable = true;

  programs.home-manager.enable = true;

  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";
}
