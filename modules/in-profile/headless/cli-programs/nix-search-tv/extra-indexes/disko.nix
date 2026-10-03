{ inputs, ... }:
{
  flake.homeModules.cli-programs =
    { config, lib, ... }:
    {
      programs.nix-search-tv.settings.experimental.options_file = {
        # Its whole option surface is one type from its own lib, as upstream's doc.nix does it.
        disko = config.lib.my.mkOpts {
          options.disko.devices = lib.mkOption {
            type = inputs.disko.lib.toplevel;
            default = { };
            description = "The devices to set up";
          };
        };
      };
    };
}
