# Personal login password for the primary user.
{ self, ... }:
let
  s = self.lib.ageSecretName ./password.age;
in
{
  flake.nixosModules.personal =
    { config, ... }:
    {
      age.secrets.${s}.rekeyFile = ./password.age;
      users.users.${config.my.primaryUser}.hashedPasswordFile = config.age.secrets.${s}.path;
    };
}
