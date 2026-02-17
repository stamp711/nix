{ self, ... }:
let
  username = "stamp";
  hostname = "ATT";
  system = "x86_64-linux";
  hostPubkey = "REPLACE_WITH_HOST_SSH_ED25519_PUBKEY";
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
          openssh.authorizedKeys.keys = [
            self.lib.sshPublicKeys.apricity
          ];
        };
      }
    ];
  };
}
