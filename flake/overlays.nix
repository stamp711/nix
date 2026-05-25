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

      gamescope = prev.gamescope.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../patches/gamescope-nvidia-hdr-toggle-flicker.patch
        ];
      });

      # Default clang-format to --fallback-style=none so it no-ops when no
      # .clang-format is present (instead of silently reformatting to LLVM).
      clang-tools = prev.symlinkJoin {
        name = prev.clang-tools.name;
        paths = [ prev.clang-tools ];
        nativeBuildInputs = [ prev.makeWrapper ];
        postBuild = ''
          rm -f $out/bin/clang-format
          makeWrapper ${prev.clang-tools}/bin/clang-format $out/bin/clang-format \
            --add-flags --fallback-style=none
        '';
        inherit (prev.clang-tools) meta;
      };

      # termite (archived 2021) requires vte 0.84.0 which currently fails
      # to build; stub it to keep environment.enableAllTerminfo working.
      termite =
        prev.runCommand "termite-stub"
          {
            outputs = [
              "out"
              "terminfo"
            ];
          }
          ''
            mkdir -p $out $terminfo/share/terminfo
          '';
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
