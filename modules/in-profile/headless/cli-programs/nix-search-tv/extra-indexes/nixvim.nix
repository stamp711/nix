{ inputs, ... }:
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      programs.nix-search-tv.settings.experimental.options_file = {
        nixvim = "${
          inputs.nixvim.packages.${pkgs.stdenv.hostPlatform.system}.options-json
        }/share/doc/nixos/options.json";
      };
    };
}
