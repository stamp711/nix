{ self, ... }:
let
  passwordSecretName = self.lib.ageSecretName ./password.age;
in
{
  flake.nixosModules.core =
    { config, ... }:
    {
      age.secrets.${passwordSecretName}.rekeyFile = ./password.age;

      users.users.${config.my.primaryUser} = {
        uid = 1000;
        isNormalUser = true;
        hashedPasswordFile = config.age.secrets.${passwordSecretName}.path;
        extraGroups = [
          "wheel"
          "networkmanager"

          "video"
          "render"
          "input"
          "uinput"
          "dialout"
          "kvm"
          "tss" # TPM access
        ];
      };
    };

  flake.darwinModules.core =
    { config, ... }:
    {
      system.primaryUser = config.my.primaryUser;
    };

  flake.homeModules.core =
    { config, ... }:
    {
      home.username = config.my.primaryUser;
    };
}
