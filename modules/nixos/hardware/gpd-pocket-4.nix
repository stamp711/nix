{
  description = "GPD Pocket 4 hardware (AMD Ryzen AI HX 370)";

  module =
    { inputs, ... }:
    {
      imports = [ inputs.nixos-hardware.nixosModules.gpd-pocket-4 ];

      hardware.enableRedistributableFirmware = true;
      hardware.bluetooth.enable = true;
    };
}
