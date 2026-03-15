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
    modules = [ self.profiles.darwin.desktop ];
  };

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system username;
    modules = [
      self.profiles.homeManager.desktop
      {
        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIaPD1BZamCmdy5VAihdkVPcXy/NKTYdT2ISfm52McKh";
        my.ssh.secretConfigFiles = [ ./ssh-config.age ];

        launchd.agents.kinit-renew = {
          enable = true;
          config = {
            ProgramArguments = [
              "/usr/bin/kinit"
              "--keychain"
            ];
            StartInterval = 14400;
            RunAtLoad = true;
            KeepAlive.SuccessfulExit = false;
            ThrottleInterval = 60;
          };
        };
      }
    ];
  };
}
