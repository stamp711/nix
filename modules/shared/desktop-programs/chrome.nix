{
  flake.homeModules.desktop-programs =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.google-chrome ];
    };
}
