{
  self,
  inputs,
  lib,
  ...
}:
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
      self.nixosModules.personal
      self.nixosModules.use-build-machine
      {
        my.primaryUser = username;
        networking.hostName = hostname;
        networking.networkmanager.enable = lib.mkForce false; # Windows owns networking
        services.tailscale.enable = lib.mkForce false; # Windows runs Tailscale
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
      self.homeModules.personal
      {
        my.primaryUser = username;
        age.rekey.hostPubkey = userPubkey;
      }
    ];
  };
}
