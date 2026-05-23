{ inputs, ... }:
{
  flake.nixosModules.my =
    { config, lib, ... }:
    let
      cfg = config.my.persistence;
      entryType = lib.types.either lib.types.str lib.types.attrs;
    in
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      options.my.persistence = {
        enable = lib.mkEnableOption "ephemeral root with /persist via impermanence";
        path = lib.mkOption {
          type = lib.types.str;
          default = "/persist";
          description = "Mountpoint backing the persisted state.";
        };
        directories = lib.mkOption {
          type = lib.types.listOf entryType;
          default = [ ];
          description = "Absolute paths to persist (system scope).";
        };
        files = lib.mkOption {
          type = lib.types.listOf entryType;
          default = [ ];
        };
        users = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ config.my.primaryUser ];
          defaultText = lib.literalExpression "[ config.my.primaryUser ]";
          description = "Users whose homes get user.directories/files persisted.";
        };
        user.directories = lib.mkOption {
          type = lib.types.listOf entryType;
          default = [ ];
          description = "Paths under each persisted user's home.";
        };
        user.files = lib.mkOption {
          type = lib.types.listOf entryType;
          default = [ ];
        };
      };

      config = lib.mkIf cfg.enable {
        environment.persistence.${cfg.path} = {
          hideMounts = true;
          inherit (cfg) directories files;
          users = lib.listToAttrs (
            map (u: lib.nameValuePair u { inherit (cfg.user) directories files; }) cfg.users
          );
        };
      };
    };
}
