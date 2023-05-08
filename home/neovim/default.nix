{config, ...}: let
  inherit (config.home.user-info) nixConfigDirectory;
  nvim = "${nixConfigDirectory}/home/neovim/nvim";
  symlink = (config.lib.file).mkOutOfStoreSymlink;
in {
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;
  xdg.configFile."nvim".source = symlink nvim;
}
