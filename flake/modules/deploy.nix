{ lib, ... }:
let
  deploy = {
    options.flake.deploy = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
      default = { };
    };
  };
in
{
  imports = [ deploy ];
  flake.flakeModules.deploy = deploy;
}
