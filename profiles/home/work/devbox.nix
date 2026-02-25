{
  description = "Home profile for work devbox";

  module =
    { self, ... }:
    {
      imports = self.homeModules.shell._all ++ self.homeModules.tools._all;

      my.zsh.secretEnvExtra = [ ./devbox-env.sh.age ];
    };
}
