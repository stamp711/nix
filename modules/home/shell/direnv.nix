{
  description = "Direnv with nix-direnv integration & mise";

  module =
    { pkgs, ... }:
    {
      # direnv
      programs.direnv = {
        enable = true;
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

      programs.mise.enable = true;
    };
}
