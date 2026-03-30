{ lib, ... }:
let
  system-manager = {
    options.flake.systemConfigs = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
    options.flake.systemModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
    };
  };
in
{
  imports = [ system-manager ];
  flake.flakeModules.system-manager = system-manager;
}
