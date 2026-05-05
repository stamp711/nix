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
      }
    ];
  };

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system;
    modules = [
      self.profiles.homeManager.headless
      self.homeModules.wakatime
      {
        my.primaryUser = username;
        age.rekey.hostPubkey = userPubkey;
        my.ssh.secretConfigFiles = [ ./ssh-hosts.conf.age ];
      }
    ];
  };
}
