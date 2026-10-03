{ inputs, ... }:
{
  flake.homeModules.cli-programs =
    { lib, pkgs, ... }:
    {
      programs.nix-search-tv.settings.experimental.options_file = {
        # Its user option defaults to system.primaryUser, so stub the one option nix-darwin
        # would have declared, then render only the tree the module owns.
        apple-container =
          let
            eval = lib.evalModules {
              modules = [
                inputs.nix-apple-container.darwinModules.default
                {
                  options.system.primaryUser = lib.mkOption { type = lib.types.str; };
                  config = {
                    _module.check = false;
                    _module.args.pkgs = pkgs;
                    system.primaryUser = "<system.primaryUser>";
                  };
                }
              ];
            };
          in
          "${
            (pkgs.nixosOptionsDoc { options = eval.options.services; }).optionsJSON
          }/share/doc/nixos/options.json";
      };
    };
}
