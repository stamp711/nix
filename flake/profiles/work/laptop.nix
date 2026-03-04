{
  homeManager =
    { self, ... }:
    {
      imports = [
        self.homeModules.shell
        self.homeModules.tools
        self.homeModules.desktop
      ];

      my.maintenance.autoUpdate = true;
      my.maintenance.autoClean = true;
      my.ssh.secretConfigFiles = [ ./ssh-config.age ];
    };
}
