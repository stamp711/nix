{
  description = "Nix development and workflow tools";

  module =
    { inputs, pkgs, ... }:
    {
      imports = [
        inputs.nix-index-database.homeModules.nix-index
      ];

      home.packages = with pkgs; [
        deploy-rs
        nh
        niv
        nixfmt
        statix
      ];

      # Nix index for command-not-found
      programs.nix-index-database.comma.enable = true;
      programs.nix-index.enable = true;
    };
}
