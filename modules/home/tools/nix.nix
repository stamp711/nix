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
        niv
        nixfmt
        nixos-anywhere
        statix
      ];

      # Nix index for command-not-found
      programs.nix-index-database.comma.enable = true;
      programs.nix-index.enable = true;

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

      # Wrapper for nix develop or nix-shell to retain the same shell inside the new environment
      programs.nix-your-shell.enable = true;
    };
}
