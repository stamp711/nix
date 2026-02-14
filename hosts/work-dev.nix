{ self }:
let
  username = "tiger";
  hostname = "n37-098-023";
  system = "x86_64-linux";
in
{
  description = "Work devbox";
  inherit username hostname system;

  homeConfiguration = self.lib.mkHome {
    inherit system username;
    modules = [ self.homeProfiles.work-devbox ];
  };

  deploy = {
    hostname = "dev";
    sshUser = username;
    remoteBuild = true;
  };
}
