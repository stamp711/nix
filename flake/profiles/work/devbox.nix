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
      my.zsh.secretEnvExtra = [ ./devbox-env.sh.age ];
    };
}
