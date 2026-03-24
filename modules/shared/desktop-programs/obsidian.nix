{ lib, ... }:
{
  flake.darwinModules.desktop-programs = {
    homebrew.casks = [ "obsidian" ];
  };

  flake.homeModules.desktop-programs =
    { pkgs, ... }:
    {
      programs.obsidian = {
        enable = true;
        package = lib.mkIf pkgs.stdenv.isDarwin null;
        cli.enable = true;
      };
      home.sessionPath = lib.mkIf pkgs.stdenv.isDarwin [
        "/Applications/Obsidian.app/Contents/MacOS"
      ];
    };
}
