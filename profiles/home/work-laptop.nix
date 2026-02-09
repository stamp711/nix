{ self, inputs, ... }:
let
  private = inputs.private;
in
{
  imports = self.homeModules.common._all ++ private.homeModules.work.shared._all;
}
