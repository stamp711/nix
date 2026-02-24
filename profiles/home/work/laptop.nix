{
  description = "Home profile for work laptop";

  module =
    { self, ... }:
    {
      imports = self.homeModules.core._all ++ self.homeModules.shell._all ++ self.homeModules.tools._all;

      programs.ssh.secretConfigFiles = [ ./ssh-config.age ];
    };
}
