# Work devbox
{ self, inputs }:
let
  host = inputs.private.work.hosts.dev;
  inherit (host) username hostname;
  system = "x86_64-linux";
in
{
  inherit username hostname system;

  homeConfiguration = self.lib.mkHome {
    inherit system username;
    modules = [ self.homeProfiles.work-devbox ];
  };

  deploy = {
    hostname = host.address;
    remoteBuild = true;
  };
}
