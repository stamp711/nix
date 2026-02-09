{ self, inputs, ... }:
let
  inherit (inputs) private;
in
{
  imports = self.homeModules.common._all ++ private.homeModules.work.shared._all;
}
