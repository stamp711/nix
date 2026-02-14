{
  description = "Home profile for work laptop";

  module =
    { self, ... }:
    {
      imports = self.homeModules.common._all ++ [
        self.homeModules.secrets.opnix
        self.homeModules.secrets.github-token
        self.homeModules.secrets.work-git
      ];

      secrets.opnix-token.reference = "op://Nix Secrets/Service Account Auth Token/Work Devices";
    };
}
