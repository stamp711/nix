{ self, ... }:
let
  username = "stamp";
  hostname = "Lius-MacBook";
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
        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOPY4NM06jrH6RsmcDvJaV0qzCLjQofmCDET89fIzyBK";
      }
    ];
  };
}
