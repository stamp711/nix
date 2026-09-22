{
  flake.nixosModules.surface =
    { pkgs, ... }:
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

      boot.loader.systemd-boot.windows."11" = {
        title = "Windows 11";
        efiDeviceHandle = "HD0b";
      };

      environment.systemPackages = [
        (pkgs.writeShellScriptBin "reboot-windows" ''
          exec systemctl reboot --boot-loader-entry=windows_11.conf
        '')
      ];

      # Keep Windows Boot Manager NVRAM entry inactive so it doesn't self-promote.
      # https://www.yhi.moe/blog/en/preventing-windows-from-modifying-your-uefi-boot-sequence
      systemd.services.deactivate-windows-boot-entry = {
        description = "Deactivate Windows Boot Manager NVRAM entry";
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.efibootmgr ];
        serviceConfig.Type = "oneshot";
        script = ''
          efibootmgr | grep -E '^Boot[0-9A-Fa-f]{4}\* Windows Boot Manager' | while read -r line; do
            num="''${line:4:4}"
            echo "Deactivating: $line"
            efibootmgr --bootnum "$num" --inactive
          done
        '';
      };

    };
}
