{ self, inputs, ... }:
let
  username = "stamp";
  hostname = "Surface";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH5Pi9art3cmYnc8yuldBqGvtLWWwSK5zjnRKF0l2MyG";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMcqFJen/UmBUeC70rkomrV3IGez6ceovQQpCWjs9WGm";
in
{
  flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
    inherit system;
    modules = [
      inputs.nixos-wsl.nixosModules.default
      self.profiles.nixos.headless
      {
        my.primaryUser = username;
        networking.hostName = hostname;
        age.rekey.hostPubkey = hostPubkey;

        wsl.enable = true;
        wsl.defaultUser = username;

        # Offload builds to NUC
        nix.distributedBuilds = true;
        nix.settings.builders-use-substitutes = true;
        nix.buildMachines = [
          {
            hostName = "NUC";
            sshUser = username;
            sshKey = "/persist/etc/ssh/ssh_host_ed25519_key";
            systems = [ system ];
            protocol = "ssh-ng";
            maxJobs = 8;
            supportedFeatures = self.nixosConfigurations.NUC.config.nix.settings.system-features;
          }
        ];
        programs.ssh.knownHosts."NUC".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClC3VLrypgdZbvJPhufSe6BeWcijyTrnl4JqBs/r566";
      }
    ];
  };

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system;
    modules = [
      self.profiles.homeManager.headless
      self.homeModules.personal
      {
        my.primaryUser = username;
        age.rekey.hostPubkey = userPubkey;
      }
    ];
  };
}
