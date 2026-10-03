{ inputs, ... }:
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      programs.nix-search-tv.settings.experimental.options_file = {
        # Its docs interpolate pkgs.path; keep the flake's store-path string to avoid
        # copying the source again during `nix flake check --no-build`.
        system-manager = "${
          (import (inputs.system-manager + "/docs/options.nix") {
            pkgs = pkgs.extend (_: _: { path = inputs.nixpkgs.outPath; });
          }).optionsJSON
        }/share/doc/nixos/options.json";
      };
    };
}
