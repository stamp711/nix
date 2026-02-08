{ self, ... }:
{
  imports = self.homeModules.common._all ++ [ self.homeModules.work.git-identity ];
}
