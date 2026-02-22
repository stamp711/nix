# NUC13RNGi9 hardware (Intel i9-13900, Intel iGPU + NVIDIA RTX 4080 via VFIO)
{ inputs, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.bluetooth.enable = true;

  # Intel iGPU for host display
  hardware.graphics.enable = true;

  # VFIO: isolate NVIDIA GPU + Aquantia 10GbE at boot for VM passthrough
  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    # 10de:2704 = RTX 4080 GPU
    # 10de:22bb = RTX 4080 audio
    # 1d6a:14c0 = Aquantia 10GbE
    "vfio-pci.ids=10de:2704,10de:22bb,1d6a:14c0"
  ];
}
