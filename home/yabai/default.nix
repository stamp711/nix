{config, ...}: let
  inherit (config.home.user-info) nixConfigDirectory;
  pwd = "${nixConfigDirectory}/home/yabai";
  symlink = (config.lib.file).mkOutOfStoreSymlink;
in {
  xdg.configFile."yabai/yabairc".source = symlink "${pwd}/yabairc";
  xdg.configFile."skhd/skhdrc".source = symlink "${pwd}/skhdrc";
}
