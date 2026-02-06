{ lib }:
let
  validFile = name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix";
in
{
  # Import all .nix files in 'dir' into an attrset.
  # Just imports, doesn't call functions.
  importDir =
    dir:
    lib.mapAttrs' (name: _: {
      name = lib.removeSuffix ".nix" name;
      value = import (dir + "/${name}");
    }) (lib.filterAttrs validFile (builtins.readDir dir));

  # Load all .nix files in 'dir', calling each with 'args'.
  loadDir =
    dir: args:
    lib.mapAttrs' (name: _: {
      name = lib.removeSuffix ".nix" name;
      value = import (dir + "/${name}") args;
    }) (lib.filterAttrs validFile (builtins.readDir dir));
}
