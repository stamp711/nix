{ pkgs, ... }:
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
  # All packages that don't need configuration
  # or don't have home-manager modules
  home.packages = with pkgs; [
    # Custom tools
    nix-clean

    # SSH tools
    assh

    # Rust development
    cargo-expand
    cargo-feature
    cargo-nextest
    cargo-watch
    rustup

    # Search tools
    fd
    ripgrep

    # Kubernetes tools
    fluxcd
    kubectl
    kubectx
    kubernetes-helm

    # Language servers
    lua-language-server
    nil
    nixd
    yaml-language-server

    # Nix tools
    nh
    niv
    nixfmt
    alejandra

    # General utilities
    imgcat
    just
    netcat
    watch
    wget
    zsh
  ];
}
