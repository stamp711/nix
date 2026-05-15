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
    modifications = _: prev: {
      # TODO: Remove once NixOS/nixpkgs#515956 lands in nixos-unstable
      openldap = prev.openldap.overrideAttrs (_: {
        doCheck = false;
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
