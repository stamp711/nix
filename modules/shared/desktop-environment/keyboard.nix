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

  flake.homeModules.desktop-environment =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.isDarwin {

      xdg.configFile."karabiner/karabiner.json".text = builtins.toJSON {
        profiles = [
          {
            name = "Default";
            selected = true;
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
                    to = [
                      {
                        key_code = "left_control";
                        lazy = true;
                      }
                    ];
                    to_if_alone = [ { key_code = "escape"; } ];
                    to_if_held_down = [ { key_code = "left_control"; } ];
                    parameters = {
                      "basic.to_if_alone_timeout_milliseconds" = 100;
                      "basic.to_if_held_down_threshold_milliseconds" = 100;
                    };
                  }
                ];
              }
            ];
          }
        ];
      };

    };
}
