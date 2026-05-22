{
  flake.nixosModules.core =
    { config, ... }:
    {
      users.users.${config.my.primaryUser} = {
        uid = 1000;
        isNormalUser = true;
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
