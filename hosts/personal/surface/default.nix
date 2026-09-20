{ self, inputs, ... }:
let
  username = "stamp";
  hostname = "Surface";
  system = "x86_64-linux";
  # Placeholders until the machine exists.
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjg9qa+d5Vv/kOmLDnV452p4HGauGEfHFprsktFKRuP";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIGuCEleqbxt6Yg6TzWiKo6hTqTT6/qvZ4iAuwmftXcV";
  disk = "/dev/disk/by-id/nvme-PLACEHOLDER";
in
{

  imports = (inputs.import-dir ./. { collect = true; })._all;

  flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
    inherit system;
    modules = [
      self.profiles.nixos.desktop
      self.nixosModules.personal
      self.nixosModules.surface
      {
        my.primaryUser = username;
        networking.hostName = hostname;
        age.rekey.hostPubkey = hostPubkey;
        age.rekey.localStorageDir = self.lib.rekeyDir hostname;
        my.boot-disk = {
          enable = true;
          layout.efi-btrfs-dual-boot = {
            esp = "${disk}-part1";
            boot = "${disk}-part4";
            root = "${disk}-part5";
            luks = true;
            swapSize = "32G";
          };
        };
      }
    ];
  };

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system;
    modules = [
      self.profiles.homeManager.desktop
      self.homeModules.personal
      {
        my.primaryUser = username;
        age.rekey.hostPubkey = userPubkey;
        age.rekey.localStorageDir = self.lib.rekeyDir "${hostname}-${username}";
      }
    ];
  };

}
