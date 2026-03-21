# Direnv with nix-direnv integration & mise
{
  flake.homeModules.cli-environment =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # direnv
      programs.direnv = {
        enable = true;
        enableZshIntegration = false; # deferred
        nix-direnv.enable = true;
        mise.enable = true;
      };

      # Devenv
      home.packages = with pkgs; [
        devenv
      ];

      programs.git.ignores = [
        # Devenv
        ".devenv*"
        "devenv.local.nix"
        "devenv.local.yaml"

        # direnv
        ".direnv"

        # pre-commit
        ".pre-commit-config.yaml"
      ];

      programs.mise = {
        enable = true;
        enableZshIntegration = false; # deferred
      };

      # Deferred zsh init for direnv and mise (pre-built, no forks at runtime)
      my.zsh-defer.initContent =
        let
          direnvInit = pkgs.runCommand "direnv-hook.zsh" { } ''
            ${lib.getExe config.programs.direnv.package} hook zsh > $out
          '';
          miseInit = pkgs.runCommand "mise-activate.zsh" { } ''
            ${lib.getExe config.programs.mise.package} activate zsh > $out
          '';
        in
        [
          { content = "source ${direnvInit}"; }
          { content = "source ${miseInit}"; }
        ];
    };
}
