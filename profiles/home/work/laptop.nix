{
  description = "Home profile for work laptop";

  module =
    { self, ... }:
    {
      imports = self.homeModules.shell._all ++ self.homeModules.tools._all;

      my.ssh.secretConfigFiles = [ ./ssh-config.age ];
    };
}
