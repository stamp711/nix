{ lib, ... }:
{
  flake.lib = {
    # Merge a list of attrsets, throwing on any name that appears in more than one.
    # Use where // would silently keep the last definition and drop the rest.
    mergeDisjoint = lib.foldl' lib.attrsets.unionOfDisjoint { };
  };
}
