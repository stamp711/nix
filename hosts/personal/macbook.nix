{ self, ... }:
let
  username = "stamp";
  hostname = "Lius-MacBook-Pro";
  system = "aarch64-darwin";
in
{
  description = "Personal MacBook";

  inherit username hostname system;

  homeConfiguration = self.lib.mkHome {
    inherit system username;
    modules = [ self.homeProfiles.personal ];
  };
}
