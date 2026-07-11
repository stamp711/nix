{
  flake.darwinModules.desktop-programs = {
    homebrew.casks = [ "zed" ];
  };

  flake.homeModules.desktop-programs =
    { pkgs, ... }:
    {
      programs.zed-editor = {
        enable = true;
        package = if pkgs.stdenv.isDarwin then null else pkgs.zed-editor;
        installRemoteServer = true;
        # Settings are managed by the zed-settings module
      };
    };
}
