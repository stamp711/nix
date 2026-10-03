{ inputs, ... }:
{
  flake.homeModules.cli-programs =
    { config, ... }:
    {
      programs.nix-search-tv.settings.experimental.options_file = {
        my-home = config.lib.my.mkOpts inputs.self.homeModules.my;
        my-nixos = config.lib.my.mkOpts inputs.self.nixosModules.my;
        my-darwin = config.lib.my.mkOpts inputs.self.darwinModules.my;
      };
    };
}
