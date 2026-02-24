{
  description = "Home profile for personal devices (Darwin & Linux)";

  module =
    { self, ... }:
    {
      imports = self.homeModules.core._all ++ self.homeModules.shell._all ++ self.homeModules.tools._all;

      programs.ssh.secretConfigFiles = [ ./ssh-hosts.conf.age ];
    };
}
