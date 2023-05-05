{
  pkgs,
  config,
  inputs,
  ...
}: let
  inherit (inputs) nix-colors;
  nix-colors-lib = nix-colors.lib.contrib {inherit pkgs;};
in {
  colorScheme = nix-colors.colorSchemes.dracula;

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
    # sh ${nix-colors-lib.shellThemeFromScheme {scheme = config.colorScheme;}}
  '';

  programs.starship.enable = true;
  programs.starship.settings = {
    git_metrics.disabled = false;
    # kubernetes.disabled = false;
    # status.disabled = false;
    # shlvl.disabled = false;
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home.sessionPath = ["$HOME/.cargo/bin"];

  home.sessionVariables = {
    # VISUAL = "hx";
    # EDITOR = "hx";
    ZSH_WAKATIME_BIN = "wakatime-cli";
  };

  home.shellAliases = {
    k = "kubectl";
    vi = "nvim";
    vim = "nvim";
  };

  programs.gpg.enable = true;
  programs.gpg.mutableKeys = false;
  programs.gpg.mutableTrust = false;
  programs.gpg.scdaemonSettings = {disable-ccid = true;};
  programs.gpg.publicKeys = [
    {
      source = ./pgp_keys/Apricity.asc;
      trust = "ultimate";
    }
  ];

  programs.lsd.enable = true;
  programs.lsd.enableAliases = true;

  programs.zoxide.enable = true;
  programs.zellij.enable = true;

  programs.tealdeer.enable = true;
  programs.tealdeer.settings.updates.auto_update = true;

  programs.btop.enable = true;
  programs.bat.enable = true;
}
