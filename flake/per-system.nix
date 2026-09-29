{
  config,
  inputs,
  self,
  ...
}:
{
  systems = import inputs.systems;

  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    {
      packages.zsh-bench = pkgs.stdenvNoCC.mkDerivation {
        name = "zsh-bench";
        src = inputs.zsh-bench;
        dontBuild = true;
        installPhase = ''
          mkdir -p $out/share/zsh-bench
          cp -r . $out/share/zsh-bench
          mkdir -p $out/bin
          ln -s $out/share/zsh-bench/zsh-bench $out/bin/zsh-bench
          ln -s $out/share/zsh-bench/human-bench $out/bin/human-bench
        '';
      };
      _module.args.pkgs = self.lib.mkPkgs { inherit system; };

      checks =
        let
          # Build checks for all configurations targeting this system.
          homeChecks = lib.mapAttrs' (name: cfg: lib.nameValuePair "home-${name}" cfg.activationPackage) (
            lib.filterAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system == system) (
              self.homeConfigurations or { }
            )
          );

          darwinChecks = lib.mapAttrs' (name: cfg: lib.nameValuePair "darwin-${name}" cfg.system) (
            lib.filterAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system == system) (
              self.darwinConfigurations or { }
            )
          );

          nixosChecks =
            lib.mapAttrs' (name: cfg: lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel)
              (
                lib.filterAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system == system) (
                  self.nixosConfigurations or { }
                )
              );

          systemChecks =
            lib.mapAttrs' (name: cfg: lib.nameValuePair "system-${name}" cfg.config.build.toplevel)
              (
                lib.filterAttrs (_: cfg: cfg.config.nixpkgs.pkgs.stdenv.hostPlatform.system == system) (
                  self.systemConfigs or { }
                )
              );
        in
        self.lib.mergeDisjoint [
          homeChecks
          darwinChecks
          nixosChecks
          systemChecks
          {
            statix = pkgs.runCommand "statix" { } ''
              ${pkgs.statix}/bin/statix check ${self} -c ${self}/statix.toml
              touch $out
            '';
            deadnix = pkgs.runCommand "deadnix" { } ''
              ${pkgs.deadnix}/bin/deadnix --fail ${self}
              touch $out
            '';
          }
        ];

      apps = {
        check = {
          type = "app";
          meta.description = "Evaluate all flake outputs without building checks";
          program = toString (
            pkgs.writeShellScript "flake-check" ''
              set -euo pipefail

              # agenix-rekey's builtins.path needs these copies before flake check
              # enters read-only store mode. This adds files without building anything.
              for directory in ${lib.escapeShellArg config.agenix-rekey.rekeyRoot}/*; do
                if [[ -d "$directory" ]]; then
                  nix store add-path "$directory" > /dev/null
                fi
              done

              # Use the caller's Nix and the same source snapshot as this app.
              exec nix flake check "$@" \
                --no-build --all-systems \
                --option allow-import-from-derivation false \
                --no-write-lock-file \
                ${lib.escapeShellArg "path:${self}"}
            ''
          );
        };

        update-inputs = {
          type = "app";
          meta.description = "Update nixpkgs to latest Hydra-cached revision and other inputs to newest";
          program = toString (
            pkgs.writeShellScript "update-nixpkgs" ''
              rev=$(${pkgs.curl}/bin/curl -sL https://channels.nixos.org/nixpkgs-unstable/git-revision)
              echo "Updating to nixpkgs-unstable: $rev"
              ${pkgs.nix}/bin/nix flake update --override-input nixpkgs "github:NixOS/nixpkgs/$rev"
            ''
          );
        };
      };

      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.statix
          pkgs.deadnix
          pkgs.nix-output-monitor
          pkgs.fx
          pkgs.treefmt
          inputs.deploy-rs.packages.${system}.default
          inputs.agenix-rekey.packages.${system}.default
        ];
      };
    };
}
