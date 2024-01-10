{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nix-colors.homeManagerModule
    inputs.nix-index-database.hmModules.nix-index
    ./terminal
    ./neovim
    # ./kitty.nix
    ./helix.nix
    # ./vscode.nix
  ];

  home.stateVersion = "22.11";

  nix.package = pkgs.nix;
  nix.settings = {experimental-features = ["nix-command" "flakes"];};

  xdg.enable = true;

  programs.home-manager.enable = true;
  programs.lazygit.enable = true;

  programs.nix-index-database.comma.enable = true;
  programs.nix-index.symlinkToCacheHome = true;
  #programs.nix-index.enable = true;

  home.packages = with pkgs; [
    alejandra
    assh
    bash
    cargo-expand
    cargo-feature
    cargo-nextest
    cargo-semver-checks
    cargo-watch
    clang-tools
    fd
    fluxcd
    glab
    imgcat
    just
    k9s
    kubectl
    kubectx
    kubernetes-helm
    lua-language-server
    mdbook
    mkcert
    netcat
    nil
    niv
    nix
    nixfmt
    nixpkgs-fmt
    nodejs
    nodePackages.prettier
    rage
    ripgrep
    rnix-lsp
    rustup
    sops
    tree-sitter
    wakatime
    watch
    wrangler
    wget
    yaml-language-server
    zsh
  ];
}
