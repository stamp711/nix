{ self, inputs, ... }:
let
  inherit (inputs) private;
in
{
  imports =
    self.homeModules.common._all
    ++ [ self.homeModules.secrets.github-token ]
    ++ private.homeModules.work.shared._all;
}
