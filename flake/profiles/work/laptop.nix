{
  homeManager =
    { self, ... }:
    {
      imports = [
        self.homeModules.shell
        self.homeModules.tools
        self.homeModules.desktop-apps
      ];

      my.maintenance.autoUpdate = true;
      my.maintenance.autoClean = true;
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
    };
}
