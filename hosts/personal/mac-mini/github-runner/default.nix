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
        ephemeral = true;
        replace = true;
        serviceOverrides = {
          # A session conflict is a plain non-zero exit, which the dictionary form leaves dead.
          KeepAlive = lib.mkForce true;
          ThrottleInterval = lib.mkForce 60;
        };
      };
    };
}
