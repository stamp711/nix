{

  flake.homeModules.desktop = {

    stylix.targets.ghostty = {
      enable = true;
      colors.enable = false;
    };

    programs.ghostty = {
      enable = true;
      settings = {
        cursor-style-blink = false;
        cursor-color = "cell-foreground";
        cursor-text = "cell-background";
        shell-integration-features = "cursor,sudo,title,ssh-env,ssh-terminfo,path";
        macos-option-as-alt = true;
        keybind = [ "global:ctrl+enter=toggle_quick_terminal" ];
        quick-terminal-position = "top";
        quick-terminal-size = "100%";
        quick-terminal-screen = "macos-menu-bar";
        quick-terminal-animation-duration = 0;
        quick-terminal-autohide = false;
        background-blur-radius = 5;
      };
    };

  };

  flake.homeModules.desktop-linux = { pkgs, ... }: {
    programs.ghostty.package = pkgs.ghostty;
  };

  flake.darwinModules.desktop-darwin = {
    homebrew.casks = [ "ghostty" ];
  };

  flake.homeModules.desktop-darwin = {
    programs.ghostty.package = null;
  };

}
