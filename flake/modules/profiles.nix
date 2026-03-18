{ lib, ... }:
let
  profiles = {
    options.flake.profiles = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.deferredModule);
      default = { };
    };
  };
in
{
  imports = [ profiles ];
  flake.flakeModules.profiles = profiles;
}
