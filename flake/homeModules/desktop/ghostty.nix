# Ghostty terminal emulator
{ pkgs, ... }:
{
  programs.ghostty = {
    enable = if pkgs.stdenv.isDarwin then false else true;
    package = if pkgs.stdenv.isDarwin then pkgs.brewCasks.ghostty else pkgs.ghostty;
    settings = {
      font-family = "Monaco Nerd Font";
    };
  };
}
