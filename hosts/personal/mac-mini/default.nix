{ inputs, self, ... }:
let
  username = "stamp";
  hostname = "Lius-Mac-mini";
  system = "aarch64-darwin";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMXmnwlO+kpz+qpq9Y0xRLVdaHbuOr4x81WH7ggNtmsw";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJDMhZj1dTWzY57OW/HlEdBeChcmknv0GWWzfinhdeYu";
in
{
  imports = (inputs.import-dir ./. { collect = true; })._all;

  flake.darwinConfigurations.${hostname} = self.lib.mkDarwin {
    inherit system;
    rekey = true;
    modules = [
      self.profiles.darwin.minimal
      self.darwinModules.personal
      self.darwinModules.mac-mini

      {
        my.primaryUser = username;
        age.rekey.hostPubkey = hostPubkey;
        age.rekey.localStorageDir = self.lib.rekeyDir hostname;

        services.containerization.enable = true;

        # Those are not in the minimal profile.
        my.maintenance.autoClean = true;
        my.maintenance.autoUpdate = true;
      }

      (self.lib.mkHomeModule {
        class = "darwin";
        inherit username;
        modules = [
          self.profiles.homeManager.minimal
          self.homeModules.personal
          self.homeModules.mac-mini
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
