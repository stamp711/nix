{ inputs, ... }:
{
  flake.homeModules.desktop-linux =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.vicinae = {
        enable = true;
        systemd.enable = true;
        extensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
          niri
        ];
      };

      wayland.windowManager.niri.settings.binds."Super+Space" = {
        _props.hotkey-overlay-title = "Toggle Vicinae";
        spawn = [
          (lib.getExe config.programs.vicinae.package)
          "toggle"
        ];
      };

      dconf.settings = {
        # GNOME reserves Super+Space for switching input sources by default.
        "org/gnome/desktop/wm/keybindings".switch-input-source =
          lib.hm.gvariant.mkEmptyArray lib.hm.gvariant.type.string;

        "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae/"
        ];

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae" = {
          name = "Vicinae";
          command = "${lib.getExe config.programs.vicinae.package} toggle";
          binding = "<Super>space";
        };
      };
    };
}
