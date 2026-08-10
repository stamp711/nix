# Personal machines ask every cache in the fleet but the one they serve.
{ lib, ... }:
let
  # Extending the submodule reads the entry's own `serve`. Reading
  # config.my.nix.binary-cache here would define the option from itself, and loop.
  useDefault = {
    options.my.nix.binary-cache = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { config, ... }:
          {
            config.use = lib.mkDefault (!config.serve);
          }
        )
      );
    };
  };
in
{
  flake.nixosModules.personal = useDefault;
  flake.darwinModules.personal = useDefault;
}
