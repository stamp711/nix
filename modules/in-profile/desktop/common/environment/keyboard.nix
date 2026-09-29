{

  flake.darwinModules.desktop-darwin = {
    system.defaults.NSGlobalDomain = {
      KeyRepeat = 1;
      InitialKeyRepeat = 15;
      AppleKeyboardUIMode = 2;
      ApplePressAndHoldEnabled = false;
    };
  };

  flake.nixosModules.desktop-linux =
    { lib, ... }:
    {
      services.keyd = {
        enable = true;
        keyboards.default = {
          ids = [ "*" ];
          settings.main.capslock = "leftcontrol";
        };
      };

      programs.dconf.profiles.user.databases = [
        {
          settings."org/gnome/desktop/peripherals/keyboard" = {
            delay = lib.gvariant.mkUint32 225;
            repeat-interval = lib.gvariant.mkUint32 15;
          };
        }
      ];
    };

  flake.homeModules.desktop-linux = {
    wayland.windowManager.niri.settings.input.keyboard = {
      repeat-delay = 225;
      repeat-rate = 67;
    };
  };

}
