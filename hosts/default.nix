{ import-dir, lib, ... }:
{
  imports = (import-dir ./. { collect = true; })._all;

  options.flake = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [
        {
          options.darwinConfigurations = lib.mkOption {
            type = lib.types.lazyAttrsOf lib.types.raw;
            default = { };
          };
          options.deploy = lib.mkOption {
            type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
            default = { };
          };
        }
      ];
    };
  };
}
