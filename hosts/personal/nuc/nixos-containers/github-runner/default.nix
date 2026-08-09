# The GitHub runner, in a container of its own. Builds still land in the host's
# store, whose daemon socket nixos-containers binds in.
{ self, ... }:
{
  flake.nixosModules.nuc =
    { config, ... }:
    let
      # PAT with this repository's Administration: Read and write. GitHub's
      # "Self-hosted runners" permission only exists at the organization level.
      pat = self.lib.mkAgeSecret config {
        rekeyFile = ./pat.age;
        # A directory of its own: systemd creates the service's /run/github-runner
        # itself, and cannot do that inside a read-only bind.
        path = "/run/github-runner-token/pat";
        # A plain file. agenix's symlink points into a per-activation generation,
        # and the bind would pin the container to whichever one existed at start.
        symlink = false;
      };
    in
    {
      age.secrets = pat.ageSecret;

      my.containers.github-runner = {
        # Write access to this directory is write access to the token in it.
        sharedDirs."/run/github-runner-token" = {
          owner = "root";
          group = "root";
          isReadOnly = true;
        };

        nixosModules = [
          self.profiles.nixos.minimal
          {
            services.github-runners.nix = {
              enable = true;
              url = "https://github.com/stamp711/nix";
              tokenFile = pat.path;
              ephemeral = true;
              serviceOverrides.MemoryMax = "24G";
              # Without this, a registration left on GitHub blocks the next one.
              replace = true;
            };
          }
        ];
      };
    };
}
