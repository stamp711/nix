# GPD Pocket 4 hardware (AMD Ryzen AI HX 370)
{ inputs, pkgs, ... }:
{
  imports = [ inputs.nixos-hardware.nixosModules.gpd-pocket-4 ];

  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = true;

  # After suspend/resume iio-sensor-proxy loses its accelerometer
  # reading and falls back to the native panel orientation (portrait),
  # flipping the display. Restarting it forces a fresh sensor read.
  systemd.services.gpd-fix-resume-rotation = {
    description = "Restart iio-sensor-proxy after resume to fix display rotation";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart iio-sensor-proxy.service";
    };
  };
}
