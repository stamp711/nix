# NUC13RNGi9 hardware (Intel i9-13900, Intel iGPU + NVIDIA RTX 4080)
{ inputs, ... }:
{
  flake.nixosModules.nuc-hardware =
    { pkgs, ... }:
    {
      imports = [
        inputs.nixos-hardware.nixosModules.common-gpu-intel
        inputs.nixos-hardware.nixosModules.common-pc-ssd
      ];
      hardware.cpu.intel.updateMicrocode = true;

      # Set intel_pstate EPP value to 64 (default 128)
      # Disable power-profiles-daemon from GNOME
      services.power-profiles-daemon.enable = false;
      boot.kernel.sysfs.devices.system.cpu."cpu[0-9]*".cpufreq.energy_performance_preference = 64;

      # Intel iGPU for host display
      hardware.graphics.enable = true;

      # NVIDIA proprietary driver with open kernel module
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia.open = true;
      hardware.nvidia.modesetting.enable = true;

      # Disable Energy Efficient Ethernet on igc NIC to prevent link flapping
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="net", DRIVERS=="igc", RUN+="${pkgs.ethtool}/bin/ethtool --set-eee $name eee off"
      '';

      my.boot-disk = {
        enable = true;
        layout = "efi-luks-btrfs";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_1TB_S6Z1NJ0W395410E";
        swapSize = "16G";
      };

      boot.loader.systemd-boot.windows."11" = {
        title = "Windows 11";
        efiDeviceHandle = "HD2b";
      };

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

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "ahci"
        "thunderbolt"
        "tpm_crb"
      ];

      boot.kernelParams = [
        "intel_iommu=on"
        "iommu=pt"
      ];
    };
}
