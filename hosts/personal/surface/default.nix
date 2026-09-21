{ self, inputs, ... }:
let
  username = "stamp";
  hostname = "Surface";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKh+qpRKfNjIsDNLsdLBu5B+4WVmxtBpFMI8vXUwBW0"; # temp
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIGuCEleqbxt6Yg6TzWiKo6hTqTT6/qvZ4iAuwmftXcV"; # temp
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
          layout.efi-btrfs-partitions = {
            esp = "/dev/disk/by-partlabel/NIXOS-ESP";
            root = "/dev/disk/by-partlabel/cryptroot";
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
