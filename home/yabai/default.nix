{config, ...}: let
  inherit (config.home.user-info) nixConfigDirectory;
  pwd = "${nixConfigDirectory}/home/yabai";
  symlink = (config.lib.file).mkOutOfStoreSymlink;
in {
  xdg.configFile."yabai".source = symlink "${pwd}/yabai";
  xdg.configFile."skhd".source = symlink "${pwd}/skhd";
}
