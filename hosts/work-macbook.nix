{ self, inputs }:
let
  host = inputs.private.work.hosts.macbook;
  inherit (host) username hostname;
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
