{
  description = "Home profile for work devbox";

  module =
    { self, ... }:
    {
      imports = self.homeModules.core._all ++ self.homeModules.shell._all ++ self.homeModules.tools._all;

      programs.zsh.secretEnvExtra = [ ./devbox-env.sh.age ];
    };
}
