{ config, pkgs, ... }: {
  home.stateVersion = "22.11";

  programs.home-manager.enable = true;

  nix.package = pkgs.nix;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
    ];
  };

  programs.zsh.enable = true;
  programs.zsh.prezto.enable = true;
  programs.zsh.prezto.pmodules = [
    "archive"
    "command-not-found"
    "directory"
    "history"
    "git"
    "gpg"
    "terminal"
    # The order matters
    "gnu-utility"
    "utility"
    "completion"
    "syntax-highlighting"
    "history-substring-search"
    "autosuggestions"
  ];
  programs.zsh.prezto.terminal.autoTitle = true;
  programs.zsh.prezto.terminal.multiplexerTitleFormat = "%s";
  programs.zsh.prezto.terminal.tabTitleFormat = "%m: %s";
  programs.zsh.prezto.terminal.windowTitleFormat = "%n@%m: %s";
  programs.zsh.initExtra = ''
    if nc -z localhost 6152 &>/dev/null; then
      export https_proxy=http://127.0.0.1:6152
      export http_proxy=http://127.0.0.1:6152
      export all_proxy=socks5://127.0.0.1:6153
    fi
  '';

  programs.starship.enable = true;
  programs.starship.settings = {
    git_metrics.disabled = false;
    # kubernetes.disabled = false;
    # status.disabled = false;
    # shlvl.disabled = false;
  };

  home.sessionVariables = {
    VISUAL = "hx";
    EDITOR = "hx";
  };

  home.shellAliases = {
    ssh = "assh wrapper ssh";
    vi = "hx";
    vim = "hx";
  };

  programs.lsd.enable = true;
  programs.lsd.enableAliases = true;

  programs.helix.enable = true;
  programs.helix.themes.kaleidoscope-light = pkgs.lib.importTOML ./helix/themes/kaleidoscope-light.toml;
  programs.helix.settings = {
    theme = "flatwhite";
    editor.line-number = "relative";
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
  programs.git.difftastic.enable = true;

  home.packages = with pkgs; [
    arkade
    assh
    helmfile
    mkcert
    netcat
    nix
    rnix-lsp
    rust-analyzer
    sops
    watch
    wget
    k9s
    kubectl
    kubernetes-helm
    kubetail
    kubie
  ];

  home.file.".kube/kubie.yaml".text = builtins.toJSON {
    # prompt.disable = true;
    prompt.zsh_use_rps1 = true;
  };
}
