# Ghostty terminal emulator
{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.brewCasks.ghostty else pkgs.ghostty;
    settings = {
      theme = "Modus Vivendi";
      font-family = "Monaco Nerd Font";
      font-size = 15;
      cursor-style-blink = false;
      shell-integration-features = "cursor,sudo,title,ssh-env,ssh-terminfo,path";
      keybind = [ "global:ctrl+enter=toggle_quick_terminal" ];
      quick-terminal-position = "top";
      quick-terminal-size = "100%";
      quick-terminal-animation-duration = 0;
      background-opacity = 0.90;
      background-blur-radius = 5;
    };
  };
}
