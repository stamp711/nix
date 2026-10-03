{ inputs, ... }:
{
  flake.homeModules.cli-programs =
    { config, lib, ... }:
    let
      # Stylix's option declarations use config.lib helpers and upstream doc stubs.
      mkStylixOpts =
        modules:
        config.lib.my.mkOpts {
          imports = [ (inputs.stylix + "/doc/eval_compat.nix") ] ++ modules;
          options.lib = lib.mkOption {
            type = lib.types.attrsOf lib.types.attrs;
            default = { };
            internal = true;
          };
        };
    in
    {
      programs.nix-search-tv.settings.experimental.options_file = {
        stylix-home-manager = mkStylixOpts [
          inputs.stylix.homeModules.stylix
          (inputs.stylix + "/doc/hm_compat.nix")
        ];
        stylix-nixos = mkStylixOpts [ inputs.stylix.nixosModules.stylix ];
        stylix-darwin = mkStylixOpts [ inputs.stylix.darwinModules.stylix ];
      };
    };
}
