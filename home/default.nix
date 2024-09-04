{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nix-colors.homeManagerModule
    inputs.nix-index-database.hmModules.nix-index
    ./terminal.nix
    ./neovim.nix
  ];

  home.stateVersion = "22.11";

  nix.package = pkgs.nix;
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  xdg.enable = true;

  programs.home-manager.enable = true;
  programs.lazygit.enable = true;

  programs.nix-index-database.comma.enable = true;
  programs.nix-index.symlinkToCacheHome = true;
  #programs.nix-index.enable = true;

  home.packages = with pkgs; [
    assh
    cargo-expand
    cargo-feature
    cargo-nextest
    cargo-watch
    fd
    fluxcd
    imgcat
    just
    kubectl
    kubectx
    kubernetes-helm
    lua-language-server
    netcat
    nil
    niv
    nix
    nixpkgs-fmt
    nixfmt-rfc-style
    ripgrep
    rustup
    watch
    wget
    yaml-language-server
    zsh
  ];
}
