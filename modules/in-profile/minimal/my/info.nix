{

  flake.homeModules.my =
    { lib, ... }:
    {
      options.my.primaryUser = lib.mkOption {
        type = lib.types.str;
        description = "Username of the primary user.";
      };
      options.my.flake = lib.mkOption {
        type = lib.types.str;
        default = "github:stamp711/nix";
        description = "Flake reference for nh and maintenance";
      };
    };

  flake.nixosModules.my =
    { lib, ... }:
    {
      options.my.primaryUser = lib.mkOption {
        type = lib.types.str;
        description = "Username of the primary user.";
      };
      options.my.flake = lib.mkOption {
        type = lib.types.str;
        default = "github:stamp711/nix";
        description = "Flake reference for nh and maintenance";
      };
    };

  flake.darwinModules.my =
    { lib, ... }:
    {
      options.my.primaryUser = lib.mkOption {
        type = lib.types.str;
        description = "Username of the primary user.";
      };
      options.my.flake = lib.mkOption {
        type = lib.types.str;
        default = "github:stamp711/nix";
        description = "Flake reference for nh and maintenance";
      };
    };

}
