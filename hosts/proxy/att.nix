{ self, ... }:
let
  username = "stamp";
  hostname = "ATT";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKWTLSyOkQ48zjJfXLWrvUkEhf7uyq8O2wcU2bcoyG2T";
in
{
  description = "Proxy server (ATT)";

  inherit username hostname system;

  deploy = {
    hostname = "proxy-att";
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
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };
      }
    ];
  };
}
