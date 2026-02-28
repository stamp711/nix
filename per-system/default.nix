{
  import-dir,
  self,
  inputs,
  ...
}:
{
  imports = (import-dir ./. { collect = true; })._all;

  systems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];

  perSystem =
    { pkgs, system, ... }:
    let
      treefmt = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = null;
        programs.nixfmt.enable = true;
        programs.stylua.enable = true;
        programs.prettier.enable = true;
        programs.clang-format.enable = true;
        settings.formatter.gersemi = {
          command = "${pkgs.gersemi}/bin/gersemi";
          options = [ "-i" ];
          includes = [
            "**/CMakeLists.txt"
            "**/*.cmake"
          ];
        };
      };
    in
    {
      _module.args.pkgs = self.lib.mkPkgs system;

      formatter = treefmt.config.build.wrapper;

      checks = {
        formatting = treefmt.config.build.check self;
        statix = pkgs.runCommand "statix" { } ''
          ${pkgs.statix}/bin/statix check ${self} -c ${self}/statix.toml
          touch $out
        '';
        deadnix = pkgs.runCommand "deadnix" { } ''
          ${pkgs.deadnix}/bin/deadnix --fail ${self}
          touch $out
        '';
        agenix-rekey =
          let
            rekey = self.lib.checkRekey {
              nixosConfigurations = self.rekeyNixosConfigurations;
              homeConfigurations = self.rekeyHomeConfigurations;
            };
            msg =
              pkgs.lib.optionalString (
                rekey.missing != [ ]
              ) "Missing rekeyed secrets: ${builtins.concatStringsSep ", " rekey.missing}\n"
              + pkgs.lib.optionalString (
                rekey.orphaned != [ ]
              ) "Orphaned files in agenix-rekey/: ${builtins.concatStringsSep ", " rekey.orphaned}\n"
              + "Run 'agenix rekey -a' to fix.";
          in
          assert rekey.missing == [ ] && rekey.orphaned == [ ] || throw msg;
          pkgs.runCommand "agenix-rekey-check" { } "touch $out";
      };

      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.statix
          pkgs.deadnix
          pkgs.nix-output-monitor
          pkgs.fx
          inputs.deploy-rs.packages.${system}.default
          inputs.agenix-rekey.packages.${system}.default
        ];
        inputsFrom = [ treefmt.config.build.devShell ];
      };
    };
}
