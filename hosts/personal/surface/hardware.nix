# Surface Pro 11 for Business (Intel, Lunar Lake)
{ inputs, ... }:
{

  flake.nixosModules.surface =
    { lib, pkgs, ... }:
    {
      my.boot-disk = {
        enable = true;
        layout.efi-btrfs-partitions = {
          esp = "/dev/disk/by-partlabel/NIXOS-ESP";
          root = "/dev/disk/by-partlabel/cryptroot";
          luks = true;
          swapSize = "32G";
        };
      };

      # The Type Cover talks over the Surface Aggregator Module, so unlocking LUKS needs it.
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

      # Firmware declares the one RT1320 twice; the ghost stops sof_sdw registering.
      boot.kernelPatches = [
        {
          name = "soundwire-dmi-quirks-surface-pro-11";
          patch = pkgs.fetchpatch {
            url = "https://patchwork.kernel.org/project/alsa-devel/patch/20260913210849.6446-1-lsa.uz@pm.me/mbox/";
            hash = "sha256-Zz8xRiQeI2U7TLIPGRVYgLUiliBXdk54fr4WatFyCZE=";
          };
        }
      ];

      specialisation.linux-surface.configuration = {
        imports = [ inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel ];
        boot.kernelPatches = lib.mkForce [ ];
      };
    };

}
