# Flake this machine tracks for nh and unattended updates.
{ lib, ... }:
let
  flakeRef = lib.mkDefault "github:stamp711/nix";
in
{
  flake.nixosModules.personal.my.flake = flakeRef;
  flake.darwinModules.personal.my.flake = flakeRef;
  flake.homeModules.personal.my.flake = flakeRef;
}
