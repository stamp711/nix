{ config, pkgs, ... }: {
  home.stateVersion = "22.11";

  programs.home-manager.enable = true;

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

  programs.starship.enable = true;

  home.sessionVariables = {
    EDITOR = "hx";
  };

  home.shellAliases = {
    ssh = "assh wrapper ssh";
    vim = "hx";
  };

  programs.helix.enable = true;
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
  };

  programs.zoxide.enable = true;
  programs.zellij.enable = true;

  programs.tealdeer.enable = true;
  programs.tealdeer.settings.updates.auto_update = true;

  programs.btop.enable = true;
  programs.bat.enable = true;

  programs.git.enable = true;
  programs.git.difftastic.enable = true;

  home.packages = with pkgs; [
    nix
    rnix-lsp
    assh
    kubectl
  ];
}
