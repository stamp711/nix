# Nix development and workflow tools
{ inputs, ... }:
{
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
      };
    };
}
