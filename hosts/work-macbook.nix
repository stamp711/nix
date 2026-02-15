{ self, ... }:
let
  username = "stamp";
  hostname = "Lius-Work-MacBook";
  system = "aarch64-darwin";
in
{
  description = "Work MacBook";
  inherit username hostname system;

  homeConfiguration = self.lib.mkHome {
    inherit system username;
    modules = [ self.homeProfiles.work-laptop ];
  };
}
