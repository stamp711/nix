{ inputs, self, ... }:
{
  flake.homeModules.cli-programs =
    { lib, pkgs, ... }:
    {
      programs.nix-search-tv.settings.experimental.options_file = {
        # storageMode's default aborts and derivation's asserts, and rendering forces both
        # whatever the config says. Drop those two; upstream leaves some descriptions empty.
        agenix-rekey =
          let
            eval = lib.evalModules {
              modules = [
                inputs.agenix-rekey.nixosModules.default
                {
                  options.networking.hostName = lib.mkOption { type = lib.types.str; };
                  config = {
                    _module.check = false;
                    _module.args.pkgs = pkgs;
                    networking.hostName = "host";
                  };
                }
              ];
            };
            age = self.lib.mergeDisjoint [
              (builtins.removeAttrs eval.options.age [ "rekey" ])
              {
                rekey = builtins.removeAttrs eval.options.age.rekey [
                  "storageMode"
                  "derivation"
                ];
              }
            ];
          in
          "${
            (pkgs.nixosOptionsDoc {
              options = { inherit age; };
              warningsAreErrors = false;
            }).optionsJSON
          }/share/doc/nixos/options.json";
      };
    };
}
