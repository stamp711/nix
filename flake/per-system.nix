{ self, inputs, ... }:
{
  systems = import inputs.systems;

  perSystem =
    { pkgs, system, ... }:
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
      _module.args.pkgs = self.lib.mkPkgs system;

      checks = {
        statix = pkgs.runCommand "statix" { } ''
          ${pkgs.statix}/bin/statix check ${self} -c ${self}/statix.toml
          touch $out
        '';
        deadnix = pkgs.runCommand "deadnix" { } ''
          ${pkgs.deadnix}/bin/deadnix --fail ${self}
          touch $out
        '';
      };

      apps = {
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
