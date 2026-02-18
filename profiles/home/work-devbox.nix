{
  description = "Home profile for work devbox";

  module =
    { self, ... }:
    {
      imports =
        self.homeModules.core._all
        ++ self.homeModules.shell._all
        ++ self.homeModules.tools._all
        ++ [
          self.homeModules.secrets.opnix
          self.homeModules.secrets.github-token
          self.homeModules.secrets.work-git
          self.homeModules.secrets.work-devbox-env
        ];

      secrets.opnix-token.reference = "op://Nix Secrets/Service Account Auth Token/Work Devices";
    };
}
