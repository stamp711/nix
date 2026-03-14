{ self, ... }:
let
  username = "stamp";
  hostname = "Lius-Work-MacBook";
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
      self.profiles.homeManager.work-laptop
      {
        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIaPD1BZamCmdy5VAihdkVPcXy/NKTYdT2ISfm52McKh";
      }
    ];
  };
}
