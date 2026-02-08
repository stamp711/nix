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

    # Binary analysis
    elf-info
    binsider

    # Security
    _1password-cli

    # SSH tools
    assh

    # C/C++
    cmake

    # Rust development
    cargo-expand
    cargo-feature
    cargo-nextest
    cargo-watch
    rustup

    # Python
    uv

    # NodeJS
    volta

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
    deploy-rs
    nh
    niv
    nixfmt
    statix

    # General utilities
    age
    age-plugin-1p
    doxygen
    eternal-terminal
    imgcat
    helix
    just
    netcat
    scc
    sops
    watch
    wakatime-cli
    wget
    zsh
  ];
}
