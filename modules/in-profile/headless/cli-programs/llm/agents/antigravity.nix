{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.antigravity-cli ];
    };
}
