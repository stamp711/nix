{ self, ... }:
let
  username = "stamp";
  hostname = "Lius-Mac-mini";
  system = "aarch64-darwin";
in
{
  flake.darwinConfigurations.${hostname} = self.lib.mkDarwin {
    inherit system;
    modules = [
      self.profiles.darwin.minimal
      self.darwinModules.personal
      { my.primaryUser = username; }
    ];
  };

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system;
    modules = [
      self.profiles.homeManager.minimal
      self.homeModules.personal
      {
        my.primaryUser = username;
        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJDMhZj1dTWzY57OW/HlEdBeChcmknv0GWWzfinhdeYu";
      }
    ];
  };
}
