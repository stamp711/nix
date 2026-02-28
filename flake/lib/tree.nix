# Tree extraction utilities for visualization
{ self, inputs }:
let
  inherit (inputs.nixpkgs) lib;

  # Extract tree with descriptions from tree of wrappers
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
            go (removeAttrs value [ "_all" ]) # Directory, recurse
          else if builtins.isAttrs value && value ? description then
            value.description # Is attrset with .description
          else
            null
        ) (removeAttrs attrs [ "_all" ]);
    in
    go;

  # List module names per class from a two-level { class.name = module } attrset
  listModules = modules: lib.mapAttrs (_class: lib.mapAttrs (_name: _mod: null)) modules;
in
{
  # Module tree for visualization (use with: nix run .#show-modules)
  moduleTree = {
    hosts = extractTree self.hosts;
    nixosModules = lib.mapAttrs (_: _: null) (self.nixosModules or { });
    homeModules = lib.mapAttrs (_: _: null) (self.homeModules or { });
    profiles = listModules (self.profiles or { });
    home = {
      configurations = extractTree self.homeConfigEntries;
    };
    deploy = extractTree self.deployNodeEntries;
    darwin = { };
    nixos = {
      configurations = extractTree self.nixosConfigEntries;
    };
  };
}
