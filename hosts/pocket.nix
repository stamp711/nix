{ self, ... }:
let
  username = "stamp";
  hostname = "GPD";
  system = "x86_64-linux";
in
{
  description = "GPD Pocket 4";
  inherit username hostname system;

  nixosConfiguration = self.lib.mkNixos {
    inherit system username;
    modules = [
      self.nixosProfiles.gpd-pocket-4
      {
        networking.hostName = hostname;

        # TODO: replace with hardware-configuration.nix from nixos-generate-config
        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
        boot.initrd.availableKernelModules = [
          "nvme"
          "xhci_pci"
          "thunderbolt"
        ];
      }
    ];
  };

  homeConfiguration = self.lib.mkHome {
    inherit system username;
    modules = [ self.homeProfiles.personal ];
  };
}
