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
    ./terminal.nix
    ./helix.nix
    ./vscode.nix
  ];

  home.stateVersion = "22.11";

  programs.home-manager.enable = true;

  # nix.package = pkgs.nix;
  # nix.settings = { experimental-features = [ "nix-command" "flakes" ]; };

  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;
  programs.neovim = {};

  programs.git.enable = true;
  programs.git.userName = "Apricity";
  programs.git.userEmail = "REDACTED";
  programs.git.signing.key = "ssh-ed25519 REDACTED";
  programs.git.signing.signByDefault = true;
  programs.git.difftastic.enable = true;
  programs.git.lfs.enable = true;
  programs.git.extraConfig = {
    init.defaultBranch = "master";
    pull.ff = "only";
    push.autoSetupRemote = true;
    gpg.format = "ssh";
    gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
    gpg.ssh.program = "${pkgs.openssh}/bin/ssh-keygen";
  };
  programs.git.ignores = [
    ".cache/"
    # direnv
    ".direnv/"
    ".envrc"
    # vscode devcontainer
    ".devcontainer/"
  ];
  home.file."${config.xdg.configHome}/git/allowed_signers".source =
    ./git_allowed_signers;

  programs.gh.enable = true;
  programs.gh.extensions = [pkgs.gh-eco];
  programs.gh.settings = {
    git_protocol = "ssh";
    prompt = "enabled";
    aliases = {
      co = "pr checkout";
      pv = "pr view";
    };
  };

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
    rnix-lsp
    rust-analyzer
    rustup
    sops
    tmux
    wakatime
    watch
    wget
    yaml-language-server
    zsh
  ];
}
