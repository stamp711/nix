{ self, inputs, ... }:
let
  username = "stamp";
  hostname = "GPD";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTQLBSo+0ienoQG9TV4XyNt3vbN60uS10OD4TUDB1an";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBt5OaxhvkIQJWZ80eX8czcCESykRu8oNlx1UIFiQz0G";
in
{
  flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
    inherit system;
    modules = [
      self.profiles.nixos.desktop
      ./hardware.nix
      ./lte.nix
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

        programs.steam.enable = true;
        programs.steam.gamescopeSession.enable = true;
      }
    ];
  };

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system;
    modules = [
      self.profiles.homeManager.desktop
      {
        my.primaryUser = username;
        age.rekey.hostPubkey = userPubkey;
        my.ssh.secretConfigFiles = [ ../ssh-hosts.conf.age ];
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
