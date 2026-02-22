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

      # Only install GNOME shell, not the bundled apps
      services.gnome.core-utilities.enable = false;
      environment.systemPackages = with pkgs; [
        gnome-terminal
        nautilus
      ];
    };
}
