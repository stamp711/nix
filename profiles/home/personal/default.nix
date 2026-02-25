{
  description = "Home profile for personal devices (Darwin & Linux)";

  module =
    { self, ... }:
    {
      imports = self.homeModules.shell._all ++ self.homeModules.tools._all;

      my.home-maintenance.autoUpdate = true;
      my.home-maintenance.autoClean = true;
      my.ssh.secretConfigFiles = [ ./ssh-hosts.conf.age ];
    };
}
