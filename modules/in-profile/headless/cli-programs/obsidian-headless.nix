{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.obsidian-headless ];
    };
}
