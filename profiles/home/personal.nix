{ self, ... }:
{
  imports = self.lib.collectModules [
    self.homeModules.common
    self.homeModules.personal
  ];
}
