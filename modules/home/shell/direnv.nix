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
        ".direnv/"
        ".devenv/"
      ];

      programs.mise.enable = true;
    };
}
