{ self, inputs }:
let
  host = inputs.private.personal.hosts.nuc;
  inherit (host) username hostname;
  system = "x86_64-linux";
in
{
  description = "Personal devbox";
  inherit username hostname system;

  homeConfiguration = self.lib.mkHome {
    inherit system username;
    modules = [ self.homeProfiles.personal ];
  };

  deploy = {
    hostname = host.address;
    remoteBuild = true;
  };
}
