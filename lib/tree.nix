# Tree extraction utilities for visualization
{ self, inputs }:
let
  inherit (inputs.nixpkgs) lib;

  # Extract module tree structure (names only) for visualization
  # Detects modules (functions or attrsets with module keys) and marks as {}
  # Only recurses into directory-like attrsets (those with _all from importDir)
  extractTree =
    let
      go =
        attrs:
        lib.mapAttrs (
          _: value:
          if builtins.isFunction value then
            { }
          else if builtins.isAttrs value && value ? _all then
            go (builtins.removeAttrs value [ "_all" ])
          else
            { }
        ) (builtins.removeAttrs attrs [ "_all" ]);
    in
    go;
in
{
  # Module tree for visualization (use with: nix run .#show-modules)
  moduleTree = {
    home = {
      modules = extractTree self.homeModules;
      profiles = extractTree self.homeProfiles;
      configurations = extractTree self.homeConfigurations;
    };
    darwin = { };
    nixos = { };
  };
}
