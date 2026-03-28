{
  flake.overlays = {
    # For every flake input, aliases 'pkgs.inputs.${flake}' to
    # 'inputs.${flake}.packages.${pkgs.system}' or
    # 'inputs.${flake}.legacyPackages.${pkgs.system}'
    # flake-inputs = final: _: {
    #   inputs = builtins.mapAttrs (
    #     _: flake: (flake.legacyPackages or flake.packages or { }).${final.stdenv.hostPlatform.system} or { }
    #   ) inputs;
    # };

    # Custom modifications to packages
    # TODO: Remove once NixOS/nixpkgs#502769 lands in nixpkgs-unstable
    modifications = _: prev: {
      direnv = prev.direnv.overrideAttrs (_: {
        postPatch = ''
          substituteInPlace GNUmakefile --replace-fail " -linkmode=external" ""
        '';
      });
    };

    # Add access to x86_64 packages on Apple Silicon
    # apple-silicon =
    #   _: prev:
    #   if prev.stdenv.hostPlatform.system == "aarch64-darwin" then
    #     {
    #       pkgs-intel = import inputs.nixpkgs {
    #         system = "x86_64-darwin";
    #         config.allowUnfree = true;
    #       };
    #     }
    #   else
    #     { };
  };
}
