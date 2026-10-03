{ lib, ... }:
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      lib.my.mkOpts =
        module:
        let
          # Get the path a declaration sits at, below the store path holding it.
          # Ours sit below a store path of the flake.
          # Without this, any edit to the flake rebuilds the document.
          relativeDeclaration =
            declaration:
            let
              below = builtins.match "/nix/store/[^/]*/(.*)" (toString declaration);
            in
            if below == null then toString declaration else lib.head below;

          # Verbatim from nixos/modules/misc/documentation.nix.
          inherit (lib)
            mapAttrs
            warn
            isAttrs
            optionalAttrs
            isDerivation
            ;
          scrubDerivations =
            namePrefix: pkgSet:
            mapAttrs (
              name: value:
              let
                wholeName = "${namePrefix}.${name}";
                guard = warn "Attempt to evaluate package ${wholeName} in option documentation; this is not supported and will eventually be an error. Use `mkPackageOption{,MD}` or `literalExpression` instead.";
              in
              if isAttrs value then
                scrubDerivations wholeName value
                // optionalAttrs (isDerivation value) {
                  outPath = guard "\${${wholeName}}";
                  drvPath = guard value.drvPath;
                }
              else
                value
            ) pkgSet;

          eval = lib.evalModules {
            modules = [
              module
              {
                _module.check = false;
                _module.args.pkgs = scrubDerivations "pkgs" pkgs;
              }
            ];
          };

          doc = pkgs.nixosOptionsDoc {
            inherit (eval) options;
            transformOptions =
              option: option // { declarations = map relativeDeclaration option.declarations; };
          };
        in
        "${doc.optionsJSON}/share/doc/nixos/options.json";
    };
}
