{ self, ... }:
{
  flake.darwinModules.mac-mini =
    { config, ... }:
    let
      pat = self.lib.mkAgeSecret config { rekeyFile = ./pat.age; };
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
