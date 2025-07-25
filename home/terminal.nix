{
  pkgs,
  config,
  inputs,
  ...
}:
let
  inherit (inputs) nix-colors;
  nix-colors-lib = nix-colors.lib.contrib { inherit pkgs; };
in
{
  colorScheme = nix-colors.colorSchemes.dracula;

  # programs.bash.enable = true;

  programs.zsh.enable = true;

  programs.zsh.autosuggestion.enable = true;
  programs.zsh.enableVteIntegration = true;
  programs.zsh.syntaxHighlighting.enable = true;

  programs.zsh.oh-my-zsh.enable = true;
  programs.zsh.oh-my-zsh.theme = "robbyrussell";
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
  ];

  programs.zsh.initContent = ''
    unset __HM_SESS_VARS_SOURCED # workaround for orbstack shells
    [ -f ~/.config/op/plugins.sh ] && source ~/.config/op/plugins.sh
    # sh ${nix-colors-lib.shellThemeFromScheme { scheme = config.colorScheme; }}
    # source extra rc in home dir if found
    [ -f ~/.zshrc_extra ] && source ~/.zshrc_extra
  '';

  programs.starship.enable = true;
  programs.starship.settings = {
    git_metrics.disabled = false;
    kubernetes.disabled = false;
    container.disabled = true;
    # status.disabled = false;
    # shlvl.disabled = false;
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home.sessionPath = [ "$HOME/.cargo/bin" ];

  home.sessionVariables = {
    VISUAL = "vim";
    EDITOR = "vim";
  };

  home.shellAliases = {
    # vi = "nvim";
    # vim = "nvim";
    ssh = "assh wrapper ssh --";
  };

  programs.lsd.enable = true;
  programs.lsd.enableZshIntegration = true;
  programs.lsd.settings.icons.theme = "unicode";

  programs.zoxide.enable = true;
  programs.tmux.enable = true;
  programs.tmux.terminal = "xterm-256color";

  programs.tealdeer.enable = true;
  programs.tealdeer.settings.updates.auto_update = true;

  programs.btop.enable = true;
  programs.bat.enable = true;

  programs.git.enable = true;
  programs.git.userName = "Apricity";
  programs.git.userEmail = "stamp1024@gmail.com";
  programs.git.signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG0Zuk/bYRvsX5WypXgY7aopBeoTNjma1rr6Txtp87JS";
  programs.git.signing.signByDefault = true;
  programs.git.delta.enable = true;
  programs.git.delta.options.side-by-side = true;
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
    ".vscode/"
  ];
  home.file."${config.xdg.configHome}/git/allowed_signers".source = ./git_allowed_signers;

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

}
