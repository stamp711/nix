{
  flake.nixosModules.desktop-linux = {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings.main.capslock = "leftcontrol";
      };
    };
  };

  flake.darwinModules.desktop-darwin = {
    system.defaults.NSGlobalDomain = {
      KeyRepeat = 1;
      InitialKeyRepeat = 15;
      AppleKeyboardUIMode = 2;
      ApplePressAndHoldEnabled = false;
    };
  };
}
