{ lib, self, ... }:
{
  flake.nixosModules.nuc =
    { config, ... }:
    let
      # PAT with this repository's Administration: Read and write.
      pat = self.lib.mkAgeSecret config {
        rekeyFile = ./pat.age;
        # Beside the service's own RuntimeDirectory, /run/github-runner.
        path = "/run/github-runner-token/pat";
        # A plain file: agenix's symlink points into a per-activation generation.
        symlink = false;
      };
    in
    {
      age.secrets = pat.ageSecret;

      my.containers.github-runner = {
        sharedDirs."/run/github-runner-token" = {
          owner = "root";
          group = "root";
          isReadOnly = true;
        };

        nixosModules = [
          self.profiles.nixos.minimal
          {
            services.github-runners.nuc = {
              enable = true;
              url = "https://github.com/stamp711/nix";
              tokenFile = pat.path;
              ephemeral = true;
              serviceOverrides = {
                MemoryMax = "24G";
                # A restart does not deregister, and GitHub holds the session
                # past the runner's own retries.
                Restart = lib.mkForce "always";
                RestartSec = 60;
              };
              replace = true;
            };
            # StartLimitIntervalSec lives in [Unit], which serviceOverrides does not write.
            systemd.services.github-runner-nuc.startLimitIntervalSec = 0;
          }
        ];
      };
    };
}
