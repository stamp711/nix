{ self, inputs }:
let
  host = inputs.private.personal.hosts.macbook;
  inherit (host) username hostname;
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
