{
  description = "Home profile for personal devices (Darwin & Linux)";

  module =
    { self, ... }:
    {
      imports = self.homeModules.shell._all ++ self.homeModules.tools._all;

      my.ssh.secretConfigFiles = [ ./ssh-hosts.conf.age ];
    };
}
