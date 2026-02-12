{
  description = "Minimal GNOME desktop on Wayland with GDM";

  module =
    { pkgs, ... }:
    {
      services.displayManager.gdm = {
        enable = true;
        wayland = true;
      };
      services.desktopManager.gnome.enable = true;

      # Auto-rotation and tablet mode
      hardware.sensor.iio.enable = true;

      # Touchpad / touchscreen
      services.libinput.enable = true;

      # Remove GNOME bloat
      environment.gnome.excludePackages = with pkgs; [
        epiphany
        geary
        gnome-characters
        gnome-maps
        gnome-music
        gnome-tour
        gnome-weather
        totem
        yelp
      ];
    };
}
