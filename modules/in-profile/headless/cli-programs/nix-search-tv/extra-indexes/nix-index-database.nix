{ inputs, ... }:
{
  flake.homeModules.cli-programs =
    { lib, pkgs, ... }:
    {
      programs.nix-search-tv.settings.experimental.options_file = {
        # It only adds comma on top of home-manager's own nix-index options, and reads their
        # enable, so stub that and render just its own tree.
        nix-index-database =
          let
            eval = lib.evalModules {
              modules = [
                inputs.nix-index-database.homeModules.nix-index
                {
                  options.programs.nix-index.enable = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                  };
                  config = {
                    _module.check = false;
                    _module.args.pkgs = pkgs;
                  };
                }
              ];
            };
          in
          "${
            (pkgs.nixosOptionsDoc {
              options = { inherit (eval.options.programs) nix-index-database; };
            }).optionsJSON
          }/share/doc/nixos/options.json";
      };
    };
}
