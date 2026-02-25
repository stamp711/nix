{
  description = "Home profile for work devbox";

  module =
    { self, ... }:
    {
      imports = self.homeModules.shell._all ++ self.homeModules.tools._all;

      my.home-maintenance.autoUpdate = true;
      my.home-maintenance.autoClean = true;
      my.zsh.secretEnvExtra = [ ./devbox-env.sh.age ];
    };
}
