{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # Tools LazyVim needs
    extraPackages = with pkgs; [
      ripgrep
      fd
    ];
  };

  # Copy LazyVim config
  xdg.configFile."nvim/init.lua".source = ./nvim/init.lua;
  xdg.configFile."nvim/lua".source = ./nvim/lua;
  xdg.configFile."nvim/lazyvim.json".source = ./nvim/lazyvim.json;
}
