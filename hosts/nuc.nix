{ self, ... }:
let
  username = "stamp";
  hostname = "NUC13RNGi9";
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
    hostname = "NUC13RNGi9.home";
    remoteBuild = true;
  };
}
