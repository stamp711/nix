{
  flake.nixosModules.surface = {

    my.boot-disk = {
      enable = true;
      layout.efi-btrfs-partitions = {
        esp = "/dev/disk/by-partlabel/NIXOS-ESP";
        root = "/dev/disk/by-partlabel/cryptroot";
        luks = true;
        swapSize = "32G";
      };
    };

    my.windows-dual-boot = {
      enable = true;
      efiDeviceHandle = "HD0b";
    };

    # The Type Cover talks over the Surface Aggregator Module, unlocking LUKS needs it.
    # https://github.com/linux-surface/linux-surface/wiki/Disk-Encryption
    boot.initrd.availableKernelModules = [
      "intel_lpss"
      "intel_lpss_pci"
      "pinctrl_intel_platform"
      "8250_dw"
      "surface_aggregator"
      "surface_aggregator_registry"
      "surface_aggregator_hub"
      "surface_hid_core"
      "surface_hid"
    ];

  };
}
