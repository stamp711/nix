{ inputs, lib, ... }:
let
  inherit (import ../lib/import.nix { inherit inputs; }) importModules;
in
{
  imports = importModules "profiles" ./.;

  options.flake = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [
        {
          options.profiles = lib.mkOption {
            type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.deferredModule);
            default = { };
            description = "Profile modules grouped by class (nixos, homeManager)";
          };
        }
      ];
    };
  };
}
