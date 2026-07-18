# Personal login password for the primary user.
{ self, ... }:
{
  flake.nixosModules.personal =
    { config, ... }:
    let
      s = self.lib.mkAgeSecret config ./password.age;
    in
    {
      age.secrets = s.ageSecret;
      users.users.${config.my.primaryUser}.hashedPasswordFile = s.path;
    };
}
