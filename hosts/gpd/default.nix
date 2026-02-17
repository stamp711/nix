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
    inherit system;
    modules = [
      self.nixosModules.common.core
      self.nixosModules.common.audio
      self.nixosModules.common.networking
      ./hardware.nix
      ./lte.nix
      self.nixosModules.desktop.gnome
      self.nixosModules.boot-disk.efi-btrfs
      {
        networking.hostName = hostname;
        boot-disk.device = "/dev/nvme0n1";
        boot.initrd.availableKernelModules = [
          "nvme"
          "xhci_pci"
          "thunderbolt"
        ];

        # Primary user
        users.users.${username} = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "networkmanager"
          ];
          openssh.authorizedKeys.keys = [
            self.lib.sshPublicKeys.apricity
          ];
        };
      }
    ];
  };

  homeConfiguration = self.lib.mkHome {
    inherit system username;
    modules = [ self.homeProfiles.personal ];
  };
}
