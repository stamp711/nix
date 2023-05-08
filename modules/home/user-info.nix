{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
in {
  options.home.user-info = {
    username = mkOption {
      type = types.str;
    };
    homeDirectory = mkOption {
      type = types.path;
    };
    nixConfigDirectory = mkOption {
      type = types.path;
    };
  };
  config.home.username = config.home.user-info.username;
  config.home.homeDirectory = config.home.user-info.homeDirectory;
}
