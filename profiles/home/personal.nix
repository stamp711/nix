{ self, ... }:
{
  imports = self.homeModules.common._all ++ self.homeModules.personal._all;
}
