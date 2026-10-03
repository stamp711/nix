{
  flake.nixosModules.desktop-linux =
    { pkgs, ... }:
    {
      programs.niri.enable = true;
      # The default Niri screen-brightness bindings call brightnessctl.
      environment.systemPackages = [ pkgs.brightnessctl ];
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
        layout.gaps = 4;
        layout.focus-ring.width = 2;

        # Let logind handle the power key to avoid suspending again after wake.
        # https://github.com/niri-wm/niri/issues/2233
        input.disable-power-key-handling = { };

        # This block replaces the included defaults; omitting tap disables tap-to-click.
        input.touchpad = {
          click-method = "clickfinger";
          natural-scroll = { };
          # Suppress accidental touchpad movement while typing.
          dwt = { };
        };
      };
    };
  };
}
