{
  flake.darwinModules.desktop-environment = {
    system.defaults.NSGlobalDomain = {
      KeyRepeat = 1;
      InitialKeyRepeat = 15;
    };
  };
}
