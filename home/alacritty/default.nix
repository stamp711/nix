{config, ...}: let
  inherit (config.home.user-info) nixConfigDirectory;
  pwd = "${nixConfigDirectory}/home/alacritty";
  symlink = (config.lib.file).mkOutOfStoreSymlink;
in {
  xdg.configFile."alacritty".source = symlink "${pwd}/alacritty";
}
