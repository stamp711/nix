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
    };
}
