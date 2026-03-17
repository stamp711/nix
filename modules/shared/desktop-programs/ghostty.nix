{
  flake.homeModules.desktop-programs =
    { pkgs, ... }:
    {
      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;
        settings = {
          theme = "Modus Vivendi";
          font-family = "Monaco Nerd Font";
          font-size = 15;
          cursor-style-blink = false;
          shell-integration-features = "cursor,sudo,title,ssh-env,ssh-terminfo,path";
          macos-option-as-alt = true;
          keybind = [ "global:ctrl+enter=toggle_quick_terminal" ];
          quick-terminal-position = "top";
          quick-terminal-size = "100%";
          quick-terminal-screen = "macos-menu-bar";
          quick-terminal-animation-duration = 0;
          quick-terminal-autohide = false;
          background-opacity = 0.90;
          background-blur-radius = 5;
        };
      };
    };

  flake.darwinModules.desktop-programs = {
    homebrew.casks = [ "ghostty" ];
  };
}
