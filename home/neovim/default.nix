{config, ...}: let
  inherit (config.home.user-info) nixConfigDirectory;
  pwd = "${nixConfigDirectory}/home/neovim";
  symlink = (config.lib.file).mkOutOfStoreSymlink;
in {
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;
  xdg.configFile."nvim".source = symlink "${pwd}/nvim";
}
