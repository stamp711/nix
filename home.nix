{ pkgs, config, nix-colors, ... }:

let nix-colors-lib = nix-colors.lib-contrib { inherit pkgs; };
in {

  imports = [ nix-colors.homeManagerModule ];

  home.stateVersion = "22.11";

  programs.home-manager.enable = true;

  colorScheme = nix-colors.colorSchemes.dracula;

  nix.package = pkgs.nix;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
    ];
  };

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

  programs.zsh.plugins = [{
    name = "zsh-nix-shell";
    src = pkgs.zsh-nix-shell;
    file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
  }];

  programs.zsh.initExtra = ''
    source ~/.config/op/plugins.sh
    if nc -z localhost 6152 &>/dev/null; then
      export https_proxy=http://127.0.0.1:6152
      export http_proxy=http://127.0.0.1:6152
      export all_proxy=socks5://127.0.0.1:6153
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

  home.sessionPath = [
     "$HOME/.cargo/bin"
   ];

  home.sessionVariables = {
    VISUAL = "hx";
    EDITOR = "hx";
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

  programs.zoxide.enable = true;
  programs.zellij.enable = true;

  programs.tealdeer.enable = true;
  programs.tealdeer.settings.updates.auto_update = true;

  programs.btop.enable = true;
  programs.bat.enable = true;

  programs.git.enable = true;
  programs.git.userName = "stamp711";
  programs.git.userEmail = "stamp1024@gmail.com";
  programs.git.signing.key =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG0Zuk/bYRvsX5WypXgY7aopBeoTNjma1rr6Txtp87JS";
  programs.git.signing.signByDefault = true;
  programs.git.difftastic.enable = true;
  programs.git.lfs.enable = true;
  programs.git.extraConfig = {
    init.defaultBranch = "master";
    pull.ff = "only";
    push.autoSetupRemote = true;
    gpg.format = "ssh";
    gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
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
    fluxcd
    imgcat
    just
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
    sops
    watch
    wget
    yaml-language-server
    zsh
  ];
}
