{ self, ... }:
let
  username = "stamp";
  hostname = "Lius-MacBook-Pro";
  system = "aarch64-darwin";
in
{
  flake.darwinConfigurations.${hostname} = self.lib.mkDarwin {
    inherit system;
    modules = [
      self.profiles.darwin.desktop
      self.darwinModules.personal
      { my.primaryUser = username; }
    ];
  };

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system;
    modules = [
      self.profiles.homeManager.desktop
      self.homeModules.personal
      {
        my.primaryUser = username;
        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1MxOTUJLMz6ehWbLVHAnhG8CR25DjmoXXUGIw3s/wN";
      }
    ];
  };
}
