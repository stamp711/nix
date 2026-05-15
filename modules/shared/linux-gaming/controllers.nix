{
  flake.nixosModules.linux-gaming = {
    # udev rules for Steam Controller etc
    hardware.steam-hardware.enable = true;
    # Virtual input device kernel module
    hardware.uinput.enable = true;
  };
}
