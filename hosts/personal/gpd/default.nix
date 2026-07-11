{ self, inputs, ... }:
let
  username = "stamp";
  hostname = "GPD";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTQLBSo+0ienoQG9TV4XyNt3vbN60uS10OD4TUDB1an";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBt5OaxhvkIQJWZ80eX8czcCESykRu8oNlx1UIFiQz0G";
in
{

  imports = (inputs.import-dir ./. { collect = true; })._all;

  flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
    inherit system;
    modules = [
      self.profiles.nixos.desktop
      self.nixosModules.linux-gaming
      self.nixosModules.personal
      self.nixosModules.gpd
      self.nixosModules.use-build-machine
      {
        my.primaryUser = username;
        networking.hostName = hostname;
        age.rekey.hostPubkey = hostPubkey;
        my.boot-disk = {
          enable = true;
          layout = "efi-luks-btrfs";
          device = "/dev/nvme0n1";
          swapSize = "32G";
        };
      }
    ];
  };

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system;
    modules = [
      self.profiles.homeManager.desktop
      self.homeModules.linux-gaming
      self.homeModules.personal
      self.homeModules.gpd
      {
        my.primaryUser = username;
        age.rekey.hostPubkey = userPubkey;
      }
    ];
  };

  flake.deploy.nodes.${hostname} = {
    hostname = "GPD.home";
    profiles = {
      home-manager = {
        user = username;
        path =
          inputs.deploy-rs.lib.${system}.activate.home-manager
            self.homeConfigurations."${username}@${hostname}";
      };
      system = {
        user = "root";
        path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${hostname};
      };
    };
  };

}
