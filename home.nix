{ config, pkgs, ... }: {
  home.stateVersion = "22.11";

  programs.home-manager.enable = true;

  programs.zsh.enable = true;
  programs.zsh.enableAutosuggestions = true;
  programs.zsh.prezto.enable = true;
  
  home.sessionVariables = {
    EDITOR = "hx";
  };
  
  programs.helix.enable = true;
  programs.zellij.enable = true;

  home.packages = with pkgs; [
    nix
    rnix-lsp
    assh
    kubectl
  ];
}
