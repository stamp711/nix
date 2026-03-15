{
  flake.homeModules.desktop-apps =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.google-chrome ];
    };
}
