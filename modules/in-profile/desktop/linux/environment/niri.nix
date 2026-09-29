{
  flake.nixosModules.desktop-linux = {
    programs.niri.enable = true;
  };

  flake.homeModules.desktop-linux = {
    wayland.windowManager.niri = {
      # NixOS already manages the session and portals.
      enable = true;
      systemd.enable = false;
      portalPackage = null;

      enableDefaultConfig = true;
      settings = {
        prefer-no-csd = { };

        # Let logind handle the power key to avoid suspending again after wake.
        # https://github.com/niri-wm/niri/issues/2233
        input.disable-power-key-handling = { };

        # This block replaces the included defaults; omitting tap disables tap-to-click.
        input.touchpad = {
          natural-scroll = { };
          # Suppress accidental touchpad movement while typing.
          dwt = { };
        };
      };
    };
  };
}
