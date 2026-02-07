{
  inputs,
  pkgs,
  config,
  ...
}:
let
  nix-colors-lib = inputs.nix-colors.lib.contrib { inherit pkgs; };
in
{
  imports = [
    inputs.nix-colors.homeManagerModules.default
  ];
  # Color scheme
  colorScheme = inputs.nix-colors.colorSchemes.dracula;

  # Zsh configuration
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableVteIntegration = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        # Productivity
        "command-not-found"
        "encode64"
        "extract"
        "fbterm"
        "history-substring-search"
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
    };
    plugins = [
      {
        name = "zsh-nix-shell";
        src = pkgs.zsh-nix-shell;
        file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
      }
    ];
    initContent = ''
      unset __HM_SESS_VARS_SOURCED # workaround for orbstack shells
      [ -f ~/.config/op/plugins.sh ] && source ~/.config/op/plugins.sh
      # Apply color scheme
      #${nix-colors-lib.shellThemeFromScheme { scheme = config.colorScheme; }}
      # source extra rc in home dir if found
      [ -f ~/.zshrc_extra ] && source ~/.zshrc_extra
    '';
  };

  programs.hstr.enable = true;

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      git_metrics.disabled = false;
      kubernetes.disabled = false;
      container.disabled = true;
    };
  };

  # direnv and nix-direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Shell environment
  home.sessionPath = [
    "$HOME/.local/bin"
    "$XDG_DATA_HOME/bob/nvim-bin"
    "$VOLTA_HOME/bin"
    "$HOME/.cargo/bin"
    "/opt/homebrew/bin"
  ];
  home.sessionVariables = {
    VOLTA_HOME = "$HOME/.volta";
    COLORTERM = "truecolor";
  };
  home.shellAliases = {
    ssh = "assh wrapper ssh --";
  };
}
