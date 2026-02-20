{ self, ... }:
let
  username = "liuxuyang.plt";
  hostname = "n37-098-023";
  system = "x86_64-linux";
in
{
  description = "Work devbox";
  inherit username hostname system;

  homeConfiguration = self.lib.mkHome {
    inherit system username;
    modules = [
      self.homeProfiles.work.devbox
      {
        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGGfAr2tMhcrbtdxi2RjGCaXCTQGWB3dBlTEXN6/DUxE";
      }
    ];
  };

  deploy = {
    hostname = "dev";
    sshUser = username;
    remoteBuild = true;
  };
}
