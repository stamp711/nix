{ lib }:
let
  # Match .nix files (excluding default.nix) or directories with default.nix
  entries =
    dir:
    let
      contents = builtins.readDir dir;
      isNixFile = name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix";
      isNixDir = name: type: type == "directory" && builtins.pathExists (dir + "/${name}/default.nix");
      validEntry = name: type: isNixFile name type || isNixDir name type;
    in
    lib.filterAttrs validEntry contents;

  # Get the import path for an entry
  entryPath =
    dir: name: type:
    if type == "directory" then dir + "/${name}" else dir + "/${name}";

  # Get the attribute name for an entry
  entryName = name: type: if type == "directory" then name else lib.removeSuffix ".nix" name;
in
{
  # Import all .nix files and directories with default.nix into an attrset.
  importDir =
    dir:
    lib.mapAttrs' (name: type: {
      name = entryName name type;
      value = import (entryPath dir name type);
    }) (entries dir);

  # Load all entries, calling each with 'args'.
  loadDir =
    dir: args:
    lib.mapAttrs' (name: type: {
      name = entryName name type;
      value = import (entryPath dir name type) args;
    }) (entries dir);
}
