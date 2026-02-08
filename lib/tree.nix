# Tree extraction utilities for visualization
{ self, inputs }:
let
  inherit (inputs.nixpkgs) lib;

  # Import modules without mapper to get raw wrappers with descriptions
  rawHomeModules = self.lib.importDir "${self}/modules/home" { collect = true; };

  # Extract tree with descriptions from raw module wrappers
  # Wrapper format: { description = "..."; module = ...; }
  # Plain module: function
  extractTree =
    let
      go =
        attrs:
        lib.mapAttrs (
          _: value:
          if builtins.isFunction value then
            null # Plain function module, no description
          else if builtins.isAttrs value && value ? _all then
            go (builtins.removeAttrs value [ "_all" ]) # Directory, recurse
          else if builtins.isAttrs value && value ? module then
            value.description or null # Wrapper: use description string directly
          else
            null # Other attrset
        ) (builtins.removeAttrs attrs [ "_all" ]);
    in
    go;
in
{
  # Module tree for visualization (use with: nix run .#show-modules)
  moduleTree = {
    home = {
      modules = extractTree rawHomeModules;
      profiles = extractTree self.homeProfiles;
      configurations = extractTree self.homeConfigEntries;
    };
    darwin = { };
    nixos = { };
  };
}
