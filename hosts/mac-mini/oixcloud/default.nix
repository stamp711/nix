{ self, ... }:
{
  flake.homeModules.mac-mini =
    { config, ... }:
    let
      token = self.lib.mkAgeSecret config { rekeyFile = ./token.age; };
    in
    {
      age.secrets = token.ageSecret;
      my.oixcloud = {
        enable = true;
        tokenFile = token.path;
        udpAdvertiseAddress = "10.0.10.10";
        udpPortCount = 1000;
      };
    };
}
