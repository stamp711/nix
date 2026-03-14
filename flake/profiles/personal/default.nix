{
  flake.profiles.homeManager.personal =
    { self, ... }:
    {
      imports = [
        self.homeModules.shell
        self.homeModules.tools
        self.homeModules.desktop-apps
      ];

      my.maintenance.autoUpdate = true;
      my.maintenance.autoClean = true;
      my.ssh.secretConfigFiles = [ ./ssh-hosts.conf.age ];
    };
}
