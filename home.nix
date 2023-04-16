{ pkgs, config, nix-vscode-extensions, nix-colors, ... }:

let nix-colors-lib = nix-colors.lib-contrib { inherit pkgs; };
in {

  imports = [ nix-colors.homeManagerModule ];

  home.stateVersion = "22.11";

  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = (pkg: true);
  nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];

  colorScheme = nix-colors.colorSchemes.dracula;

  nix.package = pkgs.nix;
  nix.settings = { experimental-features = [ "nix-command" "flakes" ]; };

  programs.bash.enable = true;

  programs.zsh.enable = true;

  programs.zsh.enableAutosuggestions = true;
  programs.zsh.enableSyntaxHighlighting = true;
  programs.zsh.enableVteIntegration = true;

  programs.zsh.oh-my-zsh.enable = true;
  programs.zsh.oh-my-zsh.theme = "af-magic";
  programs.zsh.oh-my-zsh.plugins = [
    # Productivity
    "command-not-found"
    "encode64"
    "extract"
    "fbterm"
    "history-substring-search"
    # "per-directory-history"
    "urltools"
    "web-search"
    # Build tools
    "git"
    "gitignore"
    "gnu-utils"
    "kubectl"
    # Distro-related
    "systemd"
    # macOS
    "brew"
    "macos"
    # Misc
    "themes"
  ];

  programs.zsh.plugins = [
    {
      name = "zsh-nix-shell";
      src = pkgs.zsh-nix-shell;
      file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
    }
    # TODO use flake inputs for this
    {
      name = "wakatime-zsh-plugin";
      file = "wakatime.plugin.zsh";
      src = builtins.fetchGit {
        url = "https://github.com/sobolevn/wakatime-zsh-plugin";
        rev = "69c6028b0c8f72e2afcfa5135b1af29afb49764a";
      };
    }
  ];

  programs.zsh.initExtra = ''
    unset __HM_SESS_VARS_SOURCED # workaround for orbstack shells
    [ -f ~/.config/op/plugins.sh ] && source ~/.config/op/plugins.sh
    if nc -z localhost 6152 &>/dev/null; then
      export http_proxy=http://127.0.0.1:6152
      export https_proxy=http://127.0.0.1:6152
      export all_proxy=socks5://127.0.0.1:6153
    else
      unset http_proxy https_proxy all_proxy
    fi
    # sh ${nix-colors-lib.shellThemeFromScheme { scheme = config.colorScheme; }}
  '';

  programs.starship.enable = true;
  programs.starship.settings = {
    git_metrics.disabled = false;
    # kubernetes.disabled = false;
    # status.disabled = false;
    # shlvl.disabled = false;
  };

  programs.direnv.enable = true;

  home.sessionPath = [ "$HOME/.cargo/bin" ];

  home.sessionVariables = {
    VISUAL = "hx";
    EDITOR = "hx";
    ZSH_WAKATIME_BIN = "wakatime-cli";
  };

  home.shellAliases = {
    k = "kubectl";
    vi = "hx";
    vim = "hx";
  };

  programs.gpg.enable = true;
  programs.gpg.mutableKeys = false;
  programs.gpg.mutableTrust = false;
  programs.gpg.scdaemonSettings = { disable-ccid = true; };
  programs.gpg.publicKeys = [{
    source = ./pgp_keys/Apricity.asc;
    trust = "ultimate";
  }];

  programs.lsd.enable = true;
  programs.lsd.enableAliases = true;

  programs.helix.enable = true;
  programs.helix.settings = {
    theme = "flatwhite";
    # editor.line-number = "relative";
    editor.true-color = true;
    editor.color-modes = true;
    editor.lsp.display-messages = true;
    editor.cursor-shape = {
      normal = "block";
      insert = "bar";
      select = "bar";
    };
    editor.whitespace.render = { tab = "all"; };
  };
  programs.helix.languages = [{
    name = "yaml";
    formatter = {
      command = "prettier";
      args = [ "--parser" "yaml" ];
    };
    config.yaml.schemas = { Kubernetes = "*"; };
  }];

  programs.vscode.enable = true;
  programs.vscode.enableUpdateCheck = false;
  programs.vscode.enableExtensionUpdateCheck = false;
  programs.vscode.mutableExtensionsDir = false;
  programs.vscode.extensions = (with pkgs.vscode-extensions; [
    brettm12345.nixfmt-vscode
    eamodio.gitlens
    github.copilot
    jnoortheen.nix-ide
    mhutchie.git-graph
    mkhl.direnv
    ms-azuretools.vscode-docker
    ms-vscode-remote.remote-ssh
    redhat.vscode-yaml
    rust-lang.rust-analyzer
    serayuzgur.crates
    tamasfe.even-better-toml
    # vadimcn.vscode-lldb error on darwin
    vscodevim.vim
    wakatime.vscode-wakatime
    zxh404.vscode-proto3
  ]) ++ (with pkgs.vscode-marketplace; [
    conradludgate.rust-playground
    rescuetime.rescuetime
  ]);
  programs.vscode.userSettings = {
    "editor.fontFamily" =
      "Menlo, Monaco, 'Courier New', monospace, Hack Nerd Font";
    "editor.formatOnSave" = true;
    "editor.inlineSuggest.enabled" = true;
    "[nix]"."editor.defaultFormatter" = "brettm12345.nixfmt-vscode";
    "redhat.telemetry.enabled" = false;
    "security.workspace.trust.enabled" = false;
    "workbench.colorTheme" = "Default Light+ Experimental";
  };

  programs.zoxide.enable = true;
  programs.zellij.enable = true;

  programs.tealdeer.enable = true;
  programs.tealdeer.settings.updates.auto_update = true;

  programs.btop.enable = true;
  programs.bat.enable = true;

  programs.git.enable = true;
  programs.git.userName = "stamp711";
  programs.git.userEmail = "REDACTED";
  programs.git.signing.key =
    "ssh-ed25519 REDACTED";
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
  home.file."${config.xdg.configHome}/git/allowed_signers".source =
    ./git_allowed_signers;

  programs.gh.enable = true;
  programs.gh.extensions = [ pkgs.gh-eco ];
  programs.gh.settings = {
    git_protocol = "ssh";
    prompt = "enabled";
    aliases = {
      co = "pr checkout";
      pv = "pr view";
    };
  };

  home.packages = with pkgs; [
    assh
    bash
    cargo-nextest
    cargo-semver-checks
    cargo-workspaces
    fluxcd
    imgcat
    just
    kubectl
    kubectx
    mdbook
    mkcert
    netcat
    nil
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
