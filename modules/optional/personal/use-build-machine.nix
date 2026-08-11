# Personal machines distribute builds to every builder in the fleet but the one they are.
{ lib, ... }:
let
  # Extending the submodule reads the entry's own `serve`. Reading
  # config.my.nix.build-machine here would define the option from itself, and loop.
  useDefault = {
    options.my.nix.build-machine = lib.mkOption {
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
