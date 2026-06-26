{
  flake.homeModules.cli-environment =
    { lib, pkgs, ... }:
    {
      programs.fish.enable = true;
      # fish enables man cache generation, but Darwin has no man package
      programs.man.generateCaches = lib.mkIf pkgs.stdenv.isDarwin false;
    };
}
