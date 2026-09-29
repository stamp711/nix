{

  flake.homeModules.desktop = {
    programs.obsidian = {
      enable = true;
      cli.enable = true;
    };
  };

  flake.homeModules.desktop-darwin = {
    programs.obsidian.package = null;
    home.sessionPath = [ "/Applications/Obsidian.app/Contents/MacOS" ];
  };

  flake.darwinModules.desktop-darwin = {
    homebrew.casks = [ "obsidian" ];
  };

}
