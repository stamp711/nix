{ config, pkgs, ... }: {
  home.stateVersion = "22.11";

  programs.home-manager.enable = true;

  programs.zsh.enable = true;
  programs.zsh.enableAutosuggestions = true;
  programs.zsh.prezto.enable = true;
  programs.zsh.prezto.prompt.theme = "off";
  
  programs.starship.enable = true;

  home.sessionVariables = {
    EDITOR = "hx";
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

  programs.zellij.enable = true;
  programs.tealdeer.enable = true;
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
