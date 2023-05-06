{...}: {
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;
  xdg.configFile."nvim/init.lua".source = ./nvim/init.lua;
  xdg.configFile."nvim/lua".source = ./nvim/lua;
}
