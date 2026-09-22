{ self, ... }:
let
  username = "stamp";
  hostname = "Lius-MacBook";
  system = "aarch64-darwin";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL4XlaStwoxbXApazEStdePP0BpKLH29smaFK/VSTsVC";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOPY4NM06jrH6RsmcDvJaV0qzCLjQofmCDET89fIzyBK";
in
{
  flake.darwinConfigurations.${hostname} = self.lib.mkDarwin {
    inherit system;
    rekey = true;
    modules = [
      self.profiles.darwin.desktop
      self.darwinModules.personal
      {
        my.primaryUser = username;
        age.rekey.hostPubkey = hostPubkey;
        age.rekey.localStorageDir = self.lib.rekeyDir hostname;
      }

      (self.lib.mkHomeModule {
        class = "darwin";
        inherit username;
        modules = [
          self.profiles.homeManager.desktop
          self.homeModules.personal
          {
            my.primaryUser = username;
            age.rekey.hostPubkey = userPubkey;
            age.rekey.localStorageDir = self.lib.rekeyDir "${hostname}-${username}";
          }
        ];
      })
    ];
  };
}
