{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
  ...
}: let
in {
  imports = [
    inputs.nix-colors.homeManagerModule
    inputs.nix-index-database.hmModules.nix-index
    ./terminal
    ./neovim
    ./helix.nix
    ./vscode.nix
  ];

  home.stateVersion = "22.11";

  programs.home-manager.enable = true;

  xdg.enable = true;

  # nix.package = pkgs.nix;
  # nix.settings = { experimental-features = [ "nix-command" "flakes" ]; };

  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;
  programs.neovim = {};

  home.packages = with pkgs; [
    alejandra
    assh
    bash
    cargo-expand
    cargo-feature
    cargo-nextest
    cargo-semver-checks
    cargo-watch
    cargo-workspaces
    comma
    fd
    fluxcd
    glab
    imgcat
    just
    k9s
    kubectl
    kubectx
    kubernetes-helm
    mdbook
    mkcert
    netcat
    nil
    niv
    nix
    nixfmt
    nixpkgs-fmt
    nodePackages.prettier
    rage
    ripgrep
    rnix-lsp
    rust-analyzer
    rustup
    sops
    tree-sitter
    wakatime
    watch
    wget
    yaml-language-server
    zsh
  ];
}
