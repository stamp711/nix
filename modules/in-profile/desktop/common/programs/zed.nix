{

  flake.homeModules.desktop = {
    programs.zed-editor = {
      enable = true;
      installRemoteServer = true;
      # Settings are managed by the zed-settings module
    };
  };

  flake.homeModules.desktop-linux = { pkgs, ... }: {
    programs.zed-editor.package = pkgs.zed-editor;
  };

  flake.darwinModules.desktop-darwin = {
    homebrew.casks = [ "zed" ];
  };

  flake.homeModules.desktop-darwin = {
    programs.zed-editor.package = null;
  };

}
