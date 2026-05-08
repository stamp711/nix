{
  flake.darwinModules.desktop-environment = {
    system.defaults.NSGlobalDomain = {
      KeyRepeat = 1;
      InitialKeyRepeat = 15;
      AppleKeyboardUIMode = 2;
    };
  };

  flake.nixosModules.desktop-environment = {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings.main.capslock = "leftcontrol";
      };
    };
  };
}
