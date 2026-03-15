{
  flake.nixosModules.core =
    { config, lib, ... }:
    {
      options.my.primaryUser = lib.mkOption {
        type = lib.types.str;
        description = "Username of the primary user.";
      };

      config = {
        users.users.${config.my.primaryUser} = {
          uid = 1000;
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };
      };
    };

  flake.darwinModules.core =
    { config, lib, ... }:
    {
      options.my.primaryUser = lib.mkOption {
        type = lib.types.str;
        description = "Username of the primary user.";
      };

      config = {
        system.primaryUser = config.my.primaryUser;
      };
    };

  flake.homeModules.core =
    { config, lib, ... }:
    {
      options.my.primaryUser = lib.mkOption {
        type = lib.types.str;
        description = "Username of the primary user.";
      };

      config = {
        home.username = config.my.primaryUser;
      };
    };
}
