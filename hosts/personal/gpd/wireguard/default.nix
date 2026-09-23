# This device's slot in the wireguard tunnel.
{ self, ... }:
{
  flake.nixosModules.gpd =
    { config, ... }:
    let
      s = self.lib.mkAgeSecret config { rekeyFile = ./private-key.age; };
    in
    {
      age.secrets = s.ageSecret;
      personal.wireguard = {
        enable = true;
        addrSuffix = 3;
        privateKeyFile = s.path;
      };
    };
}
