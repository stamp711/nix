{
  description = "Home profile for personal devices (Darwin & Linux)";

  module =
    { self, inputs, ... }:
    let
      inherit (inputs) private;
    in
    {
      imports =
        self.homeModules.common._all
        ++ self.homeModules.personal._all
        ++ self.homeModules.secrets._all
        ++ private.homeModules.personal._all;

      secrets.opnix-token.reference = "op://Nix Secrets/Service Account Auth Token/Personal Devices";
    };
}
