{ inputs, self, ... }:
{
  flake.homeModules.cli-programs =
    { lib, pkgs, ... }:
    let
      # NOTE: unf's `args.pkgs = mkForce …` misses a `lib.`, bites when the module reads pkgs.
      # TODO: fork and fix unf, then fold mkOptsRaw back into mkOpts.
      mkOpts =
        self: module:
        "${inputs.unf.lib.json {
          inherit self pkgs;
          modules = [ module ];
        }}";

      # Get the path a declaration sits at, below the store path holding it.
      # Ours sit below a store path of the flake.
      # Without this, any edit to the flake rebuilds the document.
      relativeDeclaration =
        declaration:
        let
          below = builtins.match "/nix/store/[^/]*/(.*)" (toString declaration);
        in
        if below == null then toString declaration else lib.head below;

      # For modules unf chokes on.
      mkOptsRaw =
        module:
        let
          eval = lib.evalModules {
            modules = [
              module
              {
                _module.check = false;
                _module.args.pkgs = pkgs;
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
    in
    {
      programs.nix-search-tv.enable = true;
      programs.nix-search-tv.settings = {
        indexes = [
          "nixpkgs"
          "home-manager"
          "nixos"
          "darwin"
          "nur"
        ];
        # Third-party module options not covered by the builtin indexes.
        experimental.options_file = {
          nixvim = "${
            inputs.nixvim.packages.${pkgs.stdenv.hostPlatform.system}.options-json
          }/share/doc/nixos/options.json";
          agenix = mkOpts inputs.agenix inputs.agenix.nixosModules.default;
          impermanence = mkOpts inputs.impermanence inputs.impermanence.nixosModules.impermanence;
          microvm = mkOpts inputs.microvm inputs.microvm.nixosModules.microvm;
          nixvirt = mkOpts inputs.NixVirt inputs.NixVirt.nixosModules.default;
          solaar = mkOpts inputs.solaar inputs.solaar.nixosModules.solaar;
          hermes-agent = mkOptsRaw inputs.hermes-agent.nixosModules.default;
          hermes-webui = mkOptsRaw inputs.hermes-webui.nixosModules.default;
          nixos-wsl = mkOptsRaw inputs.nixos-wsl.nixosModules.default;
          # Its whole option surface is one type from its own lib, as upstream's doc.nix does it.
          disko = mkOptsRaw {
            options.disko.devices = lib.mkOption {
              type = inputs.disko.lib.toplevel;
              default = { };
              description = "The devices to set up";
            };
          };
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
          nix-homebrew = mkOptsRaw inputs.nix-homebrew.darwinModules.nix-homebrew;
          # It only adds comma on top of home-manager's own nix-index options, and reads their
          # enable, so stub that and render just its own tree.
          nix-index-database =
            let
              eval = lib.evalModules {
                modules = [
                  inputs.nix-index-database.homeModules.nix-index
                  {
                    options.programs.nix-index.enable = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                    };
                    config = {
                      _module.check = false;
                      _module.args.pkgs = pkgs;
                    };
                  }
                ];
              };
            in
            "${
              (pkgs.nixosOptionsDoc {
                options = { inherit (eval.options.programs) nix-index-database; };
              }).optionsJSON
            }/share/doc/nixos/options.json";
          # NOTE: Its docs.nix imports out of pkgs.path, which breaks `nix flake check --no-build`.
          system-manager = "${
            inputs.system-manager.docs.${pkgs.stdenv.hostPlatform.system}.optionsJSON
          }/share/doc/nixos/options.json";
          my-home = mkOpts inputs.self inputs.self.homeModules.my;
          my-nixos = mkOptsRaw inputs.self.nixosModules.my;
          my-darwin = mkOpts inputs.self inputs.self.darwinModules.my;
        };
      };
    };
}
