{ lib, ... }:
{
  flake.homeModules.my =
    { config, options, ... }:
    {
      options.my.primaryUser = lib.mkOption {
        type = lib.types.str;
        description = "Username of the primary user.";
      };
      options.my.flake = lib.mkOption {
        type = lib.types.str;
        description = "Flake reference for nh and maintenance";
      };

      config.home.sessionVariables.NH_FLAKE = lib.mkIf options.my.flake.isDefined config.my.flake;
    };

  flake.nixosModules.my =
    { config, options, ... }:
    {
      options.my.primaryUser = lib.mkOption {
        type = lib.types.str;
        description = "Username of the primary user.";
      };
      options.my.flake = lib.mkOption {
        type = lib.types.str;
        description = "Flake reference for nh and maintenance";
      };

      config.environment.variables.NH_FLAKE = lib.mkIf options.my.flake.isDefined config.my.flake;
    };

  flake.darwinModules.my =
    { config, options, ... }:
    {
      options.my.primaryUser = lib.mkOption {
        type = lib.types.str;
        description = "Username of the primary user.";
      };
      options.my.flake = lib.mkOption {
        type = lib.types.str;
        description = "Flake reference for nh and maintenance";
      };

      config.environment.variables.NH_FLAKE = lib.mkIf options.my.flake.isDefined config.my.flake;
    };
}
