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
        # unf evaluates a module standalone into an options.json; disko,
        # system-manager, agenix-rekey, and nixos-wsl don't evaluate in isolation.
        experimental.options_file =
          let
            mkOpts =
              self: module:
              "${inputs.unf.lib.json {
                inherit self pkgs;
                modules = [ module ];
              }}";
          in
          {
            nvf = "${
              inputs.nvf.packages.${pkgs.stdenv.hostPlatform.system}.docs-json
            }/share/doc/nvf/options.json";
            agenix = mkOpts inputs.agenix inputs.agenix.nixosModules.default;
            impermanence = mkOpts inputs.impermanence inputs.impermanence.nixosModules.impermanence;
            microvm = mkOpts inputs.microvm inputs.microvm.nixosModules.microvm;
            nixvirt = mkOpts inputs.NixVirt inputs.NixVirt.nixosModules.default;
            solaar = mkOpts inputs.solaar inputs.solaar.nixosModules.solaar;

            my-home = mkOpts inputs.self inputs.self.homeModules.my;
            my-nixos = mkOpts inputs.self inputs.self.nixosModules.my;
            my-darwin = mkOpts inputs.self inputs.self.darwinModules.my;
          };
      };
    };
}
