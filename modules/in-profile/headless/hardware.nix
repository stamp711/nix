{
  flake.nixosModules.hardware = {
    hardware.enableRedistributableFirmware = true;
    hardware.bluetooth.enable = true;
    security.tpm2.enable = true;

    boot.initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "thunderbolt"
      "usbhid"
    ];
    # Auto-authorize Thunderbolt devices in initrd
    boot.initrd.services.udev.rules = ''
      ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
    '';

    my.persistence.directories = [
      "/var/lib/bluetooth" # paired devices; bluez refuses symlinks, needs real bind
      "/var/lib/boltd" # authorized Thunderbolt devices
    ];
  };
}
