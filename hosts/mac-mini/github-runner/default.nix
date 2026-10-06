{ lib, self, ... }:
{
  flake.darwinModules.mac-mini =
    { config, ... }:
    let
      # nix-darwin's configure script reads the token unprivileged.
      pat = self.lib.mkAgeSecret config {
        rekeyFile = ./pat.age;
        owner = "_github-runner";
      };
    in
    {
      age.secrets = pat.ageSecret;

      services.github-runners.mac-mini = {
        enable = true;
        url = "https://github.com/stamp711/nix";
        tokenFile = pat.path;
        replace = true;
        serviceOverrides = {
          # Session conflict is a non-zero exit and needs restart.
          KeepAlive = true;
          ThrottleInterval = lib.mkForce 60;
        };
      };
    };
}
