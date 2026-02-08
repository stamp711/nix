# Nix development and workflow tools
{ inputs, pkgs, ... }:
let
  nix-clean = pkgs.writeShellScriptBin "nix-clean" ''
    echo "Expire home-manager generations..."
    home-manager expire-generations 0s
    echo "Wiping nix profile history..."
    nix profile wipe-history
    echo "Running garbage collection..."
    nix store gc
  '';
in
{
  imports = [
    inputs.nix-index-database.homeModules.nix-index
  ];

  home.packages = with pkgs; [
    nix-clean
    deploy-rs
    nh
    niv
    nixfmt
    statix
  ];

  # Nix index for command-not-found
  programs.nix-index-database.comma.enable = true;
  programs.nix-index.enable = true;
}
