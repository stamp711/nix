# NUC13RNGi9 hardware (Intel i9-13900, Intel iGPU + NVIDIA RTX 4080)
{ inputs, ... }:
{

  flake.nixosModules.nuc =
    { pkgs, ... }:
    {

      imports = [
        inputs.nixos-hardware.nixosModules.common-gpu-intel
        inputs.nixos-hardware.nixosModules.common-pc-ssd
      ];

      hardware.cpu.intel.updateMicrocode = true;

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

      # Set intel_pstate EPP value to 64 (default 128)
      # Disable power-profiles-daemon from GNOME
      services.power-profiles-daemon.enable = false;
      boot.kernel.sysfs.devices.system.cpu."cpu[0-9]*".cpufreq.energy_performance_preference = 64;

      # Disable all sleep states.
      systemd.targets.sleep.enable = false;
      systemd.targets.suspend.enable = false;
      systemd.targets.hibernate.enable = false;
      systemd.targets.hybrid-sleep.enable = false;

      # Disable Energy Efficient Ethernet on igc NIC to prevent link flapping
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="net", DRIVERS=="igc", RUN+="${pkgs.ethtool}/bin/ethtool --set-eee $name eee off"
      '';

    };
}
