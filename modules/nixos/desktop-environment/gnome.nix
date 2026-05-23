{
  flake.nixosModules.desktop-environment =
    { lib, pkgs, ... }:
    {
      services.desktopManager.gnome.enable = true;

      # Auto-rotation and tablet mode
      hardware.sensor.iio.enable = true;

      # Touchpad / touchscreen
      services.libinput.enable = true;

      # Only install GNOME shell, not the bundled apps
      services.gnome.core-apps.enable = false;
      environment.systemPackages = with pkgs; [
        gnome-terminal
        nautilus
      ];

      # System-wide keyboard repeat settings
      programs.dconf.profiles.user.databases = [
        {
          settings."org/gnome/desktop/peripherals/keyboard" = {
            delay = lib.gvariant.mkUint32 225;
            repeat-interval = lib.gvariant.mkUint32 15;
          };
        }
      ];

      # GNOME-adjacent runtime state.
      # Per-entry user/group are fresh-install safety nets (no-op on migration,
      # since impermanence doesn't chmod/chown existing dirs).
      my.persistence.directories = [
        "/var/lib/AccountsService" # avatars, last-session, language per user
        {
          directory = "/var/lib/colord";
          user = "colord";
          group = "colord";
        }
        "/var/lib/upower" # battery history (no-op on desktops)
      ];
    };
}
