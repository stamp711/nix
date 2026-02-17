{ self, ... }:
let
  username = "stamp";
  hostname = "NURO";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB50dHwZLQyKtq7VV9pa9F4QJJtGW0jgJ+RsV/x2IpJI";
in
{
  description = "Proxy server (NURO)";

  inherit username hostname system;

  deploy = {
    hostname = "proxy-nuro";
    remoteBuild = false;
  };

  nixosConfiguration = self.lib.mkNixos {
    inherit system;
    modules = [
      self.nixosProfiles.kvm-proxy
      {
        networking.hostName = hostname;
        age.rekey.hostPubkey = hostPubkey;

        # Primary user
        users.users.${username} = {
          uid = 1000;
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };
      }
    ];
  };
}
