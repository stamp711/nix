# NUC13RNGi9 hardware (Intel i9-13900, Intel iGPU + NVIDIA RTX 4080)
{
  self,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    self.nixosModules.boot-disk.efi-btrfs-luks
  ];
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.bluetooth.enable = true;

  # Intel iGPU for host display
  hardware.graphics.enable = true;

  # Disable Energy Efficient Ethernet on igc NIC to prevent link flapping
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", DRIVERS=="igc", RUN+="${pkgs.ethtool}/bin/ethtool --set-eee $name eee off"
  '';

  boot-disk.device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_1TB_S6Z1NJ0W395410E";
  boot-disk.swapSize = "16G";
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
}
