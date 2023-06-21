{ pkgs, ...}: {
  programs.kitty.enable = true;
  programs.kitty.font = {
    package = pkgs.nerdfonts.override { fonts = [ "UbuntuMono" ]; };
    name = "UbuntuMono Nerd Font";
    size = 16;
  };
  programs.kitty.shellIntegration.mode = "no-cursor";
  programs.kitty.settings = {
    cursor_blink_interval = 0;
    initial_window_width = "150c";
    initial_window_height = "45c";
    background_opacity = "0.8";
  };
}
