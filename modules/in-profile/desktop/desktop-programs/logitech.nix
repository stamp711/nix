{
  flake.nixosModules.desktop-programs = {
    programs.solaar.enable = true;
  };

  flake.darwinModules.desktop-programs = {
    # homebrew.casks = [ "logi-options+" ];
  };
}
