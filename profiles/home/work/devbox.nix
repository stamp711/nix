{
  description = "Home profile for work devbox";

  module =
    { self, ... }:
    {
      imports = self.homeModules.core._all ++ self.homeModules.shell._all ++ self.homeModules.tools._all;

      programs.git.signing.key = self.lib.sshPublicKeys.work;
      programs.zsh.secretEnvExtra = [
        ./vcs-identity.sh.age
        ./devbox-env.sh.age
      ];
    };
}
