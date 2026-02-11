{ self, inputs, ... }:
let
  inherit (inputs) private;
in
{
  imports =
    self.homeModules.common._all
    ++ [
      self.homeModules.secrets.opnix
      self.homeModules.secrets.github-token
    ]
    ++ private.homeModules.work.shared._all;

  secrets.opnix-token.reference = "op://Nix Secrets/Service Account Auth Token/Work Devices";
}
