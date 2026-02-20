{ self, ... }:
let
  username = "stamp";
  hostname = "VIA";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJpjV+/0kUmxzzBXYb+o1fVDX4qKMdgj3Wq1tJH92Vkw";
in
{
  description = "Proxy server (Broadband VIA)";

  inherit username hostname system;

  deploy = {
    hostname = "proxy-via";
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
