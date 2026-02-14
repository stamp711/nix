{
  description = "Home profile for personal devices (Darwin & Linux)";

  module =
    { self, ... }:
    {
      imports =
        self.homeModules.common._all
        ++ self.homeModules.personal._all
        ++ [
          self.homeModules.secrets.opnix
          self.homeModules.secrets.github-token
          self.homeModules.secrets.personal-git
        ];

      secrets.opnix-token.reference = "op://Nix Secrets/Service Account Auth Token/Personal Devices";
    };
}
