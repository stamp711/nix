{ lib, ... }:
let
  darwin = {
    options.flake.darwinConfigurations = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
    options.flake.darwinModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
    };
  };
in
{
  imports = [ darwin ];
  flake.flakeModules.darwin = darwin;
}
