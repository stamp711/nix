{
  description = "Home profile for personal devices (Darwin & Linux)";

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
          self.homeModules.secrets.personal-git
        ];

      programs.ssh.secretConfigFiles = [ ./ssh-hosts.conf.age ];

      secrets.opnix-token.reference = "op://Nix Secrets/Service Account Auth Token/Personal Devices";
    };
}
