{ self, ... }:
{
  flake.nixosModules.nuc =
    { config, ... }:
    let
      # PAT with this repository's Administration: Read and write. GitHub's
      # "Self-hosted runners" permission only exists at the organization level.
      pat = self.lib.mkAgeSecret config { rekeyFile = ./pat.age; };
    in
    {
      age.secrets = pat.ageSecret;

      services.github-runners.nix = {
        enable = true;
        url = "https://github.com/stamp711/nix";
        tokenFile = pat.path;
        ephemeral = true;
        # Without this, a registration left on GitHub blocks the next one.
        replace = true;
      };
    };
}
