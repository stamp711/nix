{ self, inputs, ... }:
let
  inherit (inputs) private;
in
{
  imports =
    self.homeModules.common._all ++ self.homeModules.personal._all ++ private.homeModules.personal._all;
}
