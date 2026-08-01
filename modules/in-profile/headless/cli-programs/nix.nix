# Nix development and workflow tools
{ inputs, ... }: {
  flake.homeModules.cli-programs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.nix-index-database.homeModules.nix-index
      ];

      home.packages = with pkgs; [
        deploy-rs
        niv
        nixfmt
        nixos-anywhere
        statix
      ];

      # Wrapper for nix develop or nix-shell to retain the same shell inside the new environment
      programs.nix-your-shell = {
        enable = true;
        enableZshIntegration = false; # deferred
      };

      # Nix index for command-not-found
      programs.nix-index-database.comma.enable = true;
      programs.nix-index = {
        enable = true;
        enableZshIntegration = false; # deferred
      };

      my.zsh-defer.initContent =
        let
          nysCfg = config.programs.nix-your-shell;
          nom = if nysCfg.nix-output-monitor.enable then "--nom" else "";
          nysInit = pkgs.runCommand "nix-your-shell-init.zsh" { } ''
            ${lib.getExe nysCfg.package} ${nom} zsh > $out
          '';
        in
        [
          { content = "source ${config.programs.nix-index.package}/etc/profile.d/command-not-found.sh"; }
          { content = "source ${nysInit}"; }
        ];

      programs.nix-init.enable = true;

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
        # NOTE: unf's `args.pkgs = mkForce …` misses a `lib.`, bites when the module reads pkgs.
        # TODO: fork and fix unf, then fold mkOptsRaw back into mkOpts.
        # agenix-rekey has no entry: rendering its options forces age.rekey.storageMode's abort default.
        experimental.options_file =
          let
            mkOpts =
              self: module:
              "${inputs.unf.lib.json {
                inherit self pkgs;
                modules = [ module ];
              }}";
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
              in
              "${(pkgs.nixosOptionsDoc { inherit (eval) options; }).optionsJSON}/share/doc/nixos/options.json";
          in
          {
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
