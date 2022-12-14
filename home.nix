{ pkgs, config, nix-colors, ... }:

let
  nix-colors-lib = nix-colors.lib-contrib { inherit pkgs; };
in
{

  imports = [
    nix-colors.homeManagerModule
  ];

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

  # programs.zsh.prezto.enable = true;
  # programs.zsh.prezto.pmodules = [
  #   "archive"
  #   "command-not-found"
  #   "directory"
  #   "history"
  #   "git"
  #   # "gpg"
  #   "terminal"
  #   # The order matters
  #   "gnu-utility"
  #   "utility"
  #   "completion"
  #   "syntax-highlighting"
  #   "history-substring-search"
  #   "autosuggestions"
  # ];
  # programs.zsh.prezto.terminal.autoTitle = true;
  # programs.zsh.prezto.terminal.multiplexerTitleFormat = "%s";
  # programs.zsh.prezto.terminal.tabTitleFormat = "%m: %s";
  # programs.zsh.prezto.terminal.windowTitleFormat = "%n@%m: %s";

  programs.zsh.plugins = [
    {
      name = "zsh-nix-shell";
      src = pkgs.zsh-nix-shell;
      file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
    }
  ];

  programs.zsh.initExtra = ''
    if nc -z localhost 6152 &>/dev/null; then
      export https_proxy=http://127.0.0.1:6152
      export http_proxy=http://127.0.0.1:6152
      export all_proxy=socks5://127.0.0.1:6153
    fi
    # bash ${nix-colors-lib.shellThemeFromScheme { scheme = config.colorScheme; }}
  '';

  programs.starship.enable = true;
  programs.starship.settings = {
    git_metrics.disabled = false;
    # kubernetes.disabled = false;
    # status.disabled = false;
    # shlvl.disabled = false;
  };

  home.sessionPath = [
    "$HOME/.krew/bin"
    "$HOME/.arkade/bin"
    "${config.xdg.dataHome}/aquaproj-aqua/bin"
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
  programs.gpg.publicKeys = [
    { source = ./pgp_keys/Apricity.asc; trust = "ultimate"; }
  ];

  programs.lsd.enable = true;
  programs.lsd.enableAliases = true;

  programs.helix.enable = true;
  programs.helix.themes.kaleidoscope-light = pkgs.lib.importTOML ./helix/themes/kaleidoscope-light.toml;
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
    editor.whitespace.render = {
      tab = "all";
    };
  };
  programs.helix.languages = [
    {
      name = "yaml";
      formatter = { command = "prettier"; args = [ "--parser" "yaml" ]; };
      config.yaml.schemas = { Kubernetes = "*"; };
    }
  ];

  programs.kakoune.enable = true;
  programs.kakoune.plugins = with pkgs.kakounePlugins; [
    kak-lsp
    active-window-kak
  ];
  programs.kakoune.config = {
    colorScheme = "kaleidoscope-light";
    numberLines.enable = true;
    numberLines.highlightCursor = true;
    ui.setTitle = true;
    ui.enableMouse = true;
  };
  programs.kakoune.extraConfig = ''
    eval %sh{kak-lsp --kakoune -s $kak_session}
    lsp-enable
  '';

  programs.zoxide.enable = true;
  programs.zellij.enable = true;

  programs.tealdeer.enable = true;
  programs.tealdeer.settings.updates.auto_update = true;

  programs.btop.enable = true;
  programs.bat.enable = true;

  programs.git.enable = true;
  programs.git.userName = "Apricity";
  programs.git.userEmail = "stamp1024@gmail.com";
  programs.git.signing.signByDefault = true;
  programs.git.signing.key = null;
  programs.git.difftastic.enable = true;
  programs.git.lfs.enable = true;
  programs.git.extraConfig = {
    init.defaultBranch = "main";
    pull.ff = "only";
    push.autoSetupRemote = true;
  };

  home.packages = with pkgs; [
    age
    arkade
    assh
    bash
    cilium-cli
    clusterctl
    fluxcd
    gh
    govc
    helmfile
    imgcat
    just
    k9s
    krew
    kubeconform
    kubectl
    kubectx
    kubernetes-helm
    kubetail
    kubespy
    kubie
    kustomize
    mkcert
    netcat
    nix
    nodePackages.prettier
    rage
    rnix-lsp
    rust-analyzer
    sops
    talosctl
    vcluster
    watch
    wget
    yaml-language-server
    yj
    zsh
  ];

  home.file.".kube/kubie.yaml".text = builtins.toJSON {
    # prompt.disable = true;
    prompt.zsh_use_rps1 = true;
  };
}
