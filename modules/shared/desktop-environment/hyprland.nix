{ inputs, ... }:
{
  flake.nixosModules.desktop-environment = {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
  };

  flake.homeModules.desktop-environment =
    { lib, pkgs, ... }:
    {
      imports = [ inputs.caelestia-shell.homeManagerModules.default ];

      config = lib.mkIf pkgs.stdenv.isLinux {
        programs.caelestia = {
          enable = true;
          systemd.target = "hyprland-session.target";
        };

        wayland.windowManager.hyprland = {
          enable = true;
          package = null; # nixosModule handles the binary
          portalPackage = null; # nixosModule handles the portal
          settings =
            let
              bind = key: lua: {
                _args = [
                  key
                  (lib.generators.mkLuaInline lua)
                ];
              };
            in
            {
              bind = [
                # App launchers
                (bind "SUPER + RETURN" ''hl.dsp.exec_cmd("ghostty")'')

                # Window management
                (bind "SUPER + Q" "hl.dsp.window.close()")
                (bind "SUPER + V" ''hl.dsp.window.float({ action = "toggle" })'')
                (bind "SUPER + F" ''hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })'')

                # Focus
                (bind "SUPER + H" ''hl.dsp.focus({ direction = "left" })'')
                (bind "SUPER + L" ''hl.dsp.focus({ direction = "right" })'')
                (bind "SUPER + K" ''hl.dsp.focus({ direction = "up" })'')
                (bind "SUPER + J" ''hl.dsp.focus({ direction = "down" })'')

                # Workspaces
                (bind "SUPER + 1" "hl.dsp.focus({ workspace = 1 })")
                (bind "SUPER + 2" "hl.dsp.focus({ workspace = 2 })")
                (bind "SUPER + 3" "hl.dsp.focus({ workspace = 3 })")
                (bind "SUPER + 4" "hl.dsp.focus({ workspace = 4 })")
                (bind "SUPER + 5" "hl.dsp.focus({ workspace = 5 })")
                (bind "SUPER + SHIFT + 1" "hl.dsp.window.move({ workspace = 1 })")
                (bind "SUPER + SHIFT + 2" "hl.dsp.window.move({ workspace = 2 })")
                (bind "SUPER + SHIFT + 3" "hl.dsp.window.move({ workspace = 3 })")
                (bind "SUPER + SHIFT + 4" "hl.dsp.window.move({ workspace = 4 })")
                (bind "SUPER + SHIFT + 5" "hl.dsp.window.move({ workspace = 5 })")

                # Pop-up terminal (scratchpad)
                (bind "SUPER + GRAVE" ''hl.dsp.workspace.toggle_special("term")'')
                (bind "SUPER + SHIFT + GRAVE" ''hl.dsp.window.move({ workspace = "special:term", follow = false })'')
              ];
            };
        };
      };
    };
}
