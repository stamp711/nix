# Directory import utilities
{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;

  # Reserved attribute name for collecting all entries
  collectAttr = "_all";

  # Extract the base name of the entry
  entryName = name: type: if type == "directory" then name else lib.removeSuffix ".nix" name;

  # Test if the entry is a .nix file (excluding default.nix)
  isNixFile = name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix";

  # Test if the entry is a dir with default.nix
  isNixDir =
    parent: name: type:
    type == "directory" && builtins.pathExists (parent + "/${name}/default.nix");

  # Test if the entry is a dir without default.nix
  isPlainDir =
    parent: name: type:
    type == "directory" && !builtins.pathExists (parent + "/${name}/default.nix");

  # Test if the name of the entry would collide with collectAttr
  isCollectAttr = name: type: entryName name type == collectAttr;

in
rec {
  # Import .nix files and directories recursively into a nested attrset tree.
  # - .nix files become entries
  # - directories with default.nix become entries
  # - directories without default.nix are recursively traversed
  # Options:
  #   args: if set, call each import with args (default: null)
  #   mapper: transform each leaf value after import (default: identity)
  #   collect: if true, add `_all` attribute with all entries at each level (default: false)
  # Note: args and mapper are mutually exclusive
  importDir =
    dir:
    {
      args ? null,
      mapper ? (x: x),
      collect ? false,
    }:
    let
      load = path: mapper (if args == null then import path else import path args);

      entries = builtins.readDir dir;

      # Entry -> { name; value; isLeaf; } | null
      # name: extracted from the entry's base name
      # value: the loaded content, or a recursive entry
      # isLeaf: false when the entry is a plain directory (recursion)
      processEntry =
        name: type:
        if isCollectAttr name type then
          builtins.trace "warning: ${dir}/${name} is ignored (${collectAttr} is reserved)" null
        else if isNixFile name type || isNixDir dir name type then
          {
            name = entryName name type;
            value = load (dir + "/${name}");
            isLeaf = true;
          }
        else if isPlainDir dir name type then
          {
            inherit name;
            value = importDir (dir + "/${name}") { inherit args mapper collect; };
            isLeaf = false;
          }
        else
          null;

      # Process into list: [ { name; value; isLeaf; } ]
      processed = builtins.filter (x: x != null) (lib.mapAttrsToList processEntry entries);

      # Into attrset: { ${name} = value; }
      attrs = builtins.listToAttrs (map (e: { inherit (e) name value; }) processed);

      # All leaf values from this subtree, flattened into a list: [ value ]
      allEntries =
        if collect then
          builtins.concatLists (map (e: if e.isLeaf then [ e.value ] else e.value.${collectAttr}) processed)
        else
          [ ];
    in
    attrs // lib.optionalAttrs collect { ${collectAttr} = allEntries; };
}
