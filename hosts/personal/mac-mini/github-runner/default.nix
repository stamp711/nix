{ self, ... }:
{
  flake.darwinModules.mac-mini =
    { config, ... }:
    let
      # The launchd job reads the token itself, running as this user.
      pat = self.lib.mkAgeSecret config {
        rekeyFile = ./pat.age;
        owner = "_github-runner";
      };
    in
    {
      age.secrets = pat.ageSecret;

      services.github-runners.nix = {
        enable = true;
        url = "https://github.com/stamp711/nix";
        tokenFile = pat.path;
        ephemeral = true;
        replace = true;
      };
    };
}
