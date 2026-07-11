{
  flake.homeModules.core =
    { lib, pkgs, ... }:
    {
      home.packages = lib.mkIf pkgs.stdenv.isLinux [
        pkgs.nix-alien
      ];
    };
}
