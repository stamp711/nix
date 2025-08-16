{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nix-colors.homeManagerModule
    inputs.nix-index-database.homeModules.nix-index

    # Modular configuration files
    ./shell.nix
    ./cli-tools.nix
    ./git
    ./packages.nix
  ];

  home.stateVersion = "25.05";
  home.username = "stamp";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/stamp" else "/home/stamp";

  nix.package = pkgs.nix;
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  xdg.enable = true;

  programs.home-manager.enable = true;
}
