{ inputs, ... }:
{
  flake.homeModules.core =
    { lib, pkgs, ... }:
    {
      home.packages = lib.mkIf pkgs.stdenv.isLinux [
        inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien
      ];
    };
}
