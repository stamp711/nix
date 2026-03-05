{ self, ... }:
let
  username = "stamp";
  hostname = "Lius-MacBook-Pro";
  system = "aarch64-darwin";
in
{
  flake.darwinConfigurations.${hostname} = self.lib.mkDarwin {
    inherit system;
    primaryUser = username;
  };

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system username;
    modules = [
      self.profiles.homeManager.personal
      {
        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1MxOTUJLMz6ehWbLVHAnhG8CR25DjmoXXUGIw3s/wN";
      }
    ];
  };
}
