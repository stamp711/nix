{
  description = "GPD Pocket 4 hardware (AMD Ryzen AI HX 370)";

  module =
    { inputs, ... }:
    {
      imports = [ inputs.nixos-hardware.nixosModules.gpd-pocket-4 ];

      hardware.enableRedistributableFirmware = true;
      hardware.bluetooth.enable = true;

      # After suspend/resume the IIO accelerometer can report a stale
      # orientation, causing GNOME to flip the rotated panel back to
      # portrait.  Restarting iio-sensor-proxy forces a fresh read.
      systemd.services.gpd-fix-resume-rotation = {
        description = "Restart iio-sensor-proxy after resume to fix display rotation";
        wantedBy = [ "post-resume.target" ];
        after = [ "post-resume.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "/run/current-system/sw/bin/systemctl restart iio-sensor-proxy.service";
        };
      };
    };
}
