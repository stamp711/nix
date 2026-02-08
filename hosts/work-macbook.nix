# Work MacBook
{ self, inputs }:
let
  host = inputs.private.work.hosts.macbook;
  inherit (host) username hostname;
  system = "aarch64-darwin";
in
{
  inherit username hostname system;

  homeConfiguration = self.lib.mkHome {
    inherit system username;
    modules = [ self.homeProfiles.work-laptop ];
  };
}
