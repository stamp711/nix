{ lib, ... }: {

  flake.darwinModules.desktop-environment = {
    system.defaults.NSGlobalDomain = {
      KeyRepeat = 1;
      InitialKeyRepeat = 15;
      AppleKeyboardUIMode = 2;
    };
    homebrew.casks = [ "karabiner-elements" ];
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

  flake.homeModules.desktop-environment = { pkgs, ... }: {
    xdg.configFile."karabiner/karabiner.json" = lib.mkIf pkgs.stdenv.isDarwin {
      force = true;
      text = builtins.toJSON {
        profiles = [
          {
            name = "Default";
            selected = true;
            virtual_hid_keyboard.keyboard_type_v2 = "ansi";
            complex_modifications.rules = [
              {
                description = "Post escape if left_control is tapped";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "left_control";
                      modifiers.optional = [ "any" ];
                    };
                    to = [ { key_code = "left_control"; } ];
                    to_if_alone = [ { key_code = "escape"; } ];
                    parameters."basic.to_if_alone_timeout_milliseconds" = 250;
                  }
                ];
              }
            ];
          }
        ];
      };

    };
  };

}
