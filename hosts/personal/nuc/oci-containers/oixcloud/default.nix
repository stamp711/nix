{ self, ... }:
{
  flake.nixosModules.nuc =
    { config, ... }:
    let
      token = self.lib.mkAgeSecret config { rekeyFile = ./oixcloud-token.age; };
    in
    {
      age.secrets = token.ageSecret;
      my.oixcloud = {
        enable = true;
        openFirewall = true;
        tokenFile = token.path;
      };
    };
}
