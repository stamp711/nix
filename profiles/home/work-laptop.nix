{ self, ... }:
{
  imports =
    self.lib.collectModules [ self.homeModules.common ]
    ++ (with self.homeModules.work; [
      git-identity
    ]);
}
