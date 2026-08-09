{
  flake.nixosModules.hardware =
    { config, lib, ... }:
    lib.mkMerge [
      {
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
      }

      # A container has none of this hardware.
      (lib.mkIf (!config.boot.isContainer) {
        hardware.enableRedistributableFirmware = true;
        hardware.bluetooth.enable = true;
        security.tpm2.enable = true;
      })

      (lib.mkIf config.hardware.bluetooth.enable {
        # Paired devices. bluez refuses a symlink, so this has to be a real bind.
        my.persistence.directories = [ "/var/lib/bluetooth" ];
      })

      (lib.mkIf config.services.hardware.bolt.enable {
        my.persistence.directories = [ "/var/lib/boltd" ]; # authorized Thunderbolt devices
      })
    ];
}
