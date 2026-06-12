{ self, inputs, ... }:
let
  username = "stamp";
  hostname = "GPD";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTQLBSo+0ienoQG9TV4XyNt3vbN60uS10OD4TUDB1an";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBt5OaxhvkIQJWZ80eX8czcCESykRu8oNlx1UIFiQz0G";
in
{
  imports = [
    ./hardware.nix
    ./fingerprint.nix
  ];

  flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
    inherit system;
    modules = [
      self.profiles.nixos.desktop
      self.nixosModules.linux-gaming
      self.nixosModules.gpd-hardware
      self.nixosModules.gpd-fingerprint
      inputs.nixos-hardware.nixosModules.gpd-pocket-4
      ./lte.nix
      self.nixosModules.tailscale
      {
        my.primaryUser = username;
        networking.hostName = hostname;
        age.rekey.hostPubkey = hostPubkey;

        # Offload builds to NUC
        nix.distributedBuilds = true;
        nix.settings.builders-use-substitutes = true;
        nix.buildMachines = [
          {
            hostName = "NUC.home";
            sshUser = username;
            sshKey = "/persist/etc/ssh/ssh_host_ed25519_key";
            systems = [ system ];
            protocol = "ssh-ng";
            maxJobs = 8;
            supportedFeatures = self.nixosConfigurations.NUC.config.nix.settings.system-features;
          }
        ];
        programs.ssh.knownHosts."NUC.home".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClC3VLrypgdZbvJPhufSe6BeWcijyTrnl4JqBs/r566";

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
      self.homeModules.personal
      self.homeModules.linux-gaming
      self.homeModules.gpd-hardware
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
