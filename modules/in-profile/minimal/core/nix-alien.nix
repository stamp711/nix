{
  flake.homeModules.core =
    { lib, pkgs, ... }:
    {
      home.packages = lib.mkIf pkgs.stdenv.hostPlatform.isLinux [
        pkgs.nix-alien
      ];
    };
}
