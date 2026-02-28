{
  homeManager =
    { self, ... }:
    {
      imports = [
        self.homeModules.shell
        self.homeModules.tools
      ];

      my.maintenance.autoUpdate = true;
      my.maintenance.autoClean = true;
      my.ssh.secretConfigFiles = [ ./ssh-hosts.conf.age ];
    };
}
