{

  flake.homeModules.desktop = { config, ... }: {

    stylix.targets.ghostty.enable = true;

    programs.ghostty = {
      enable = true;
      settings = {
        # Base16's extra terminal slots; Stylix currently sets only 0–15.
        palette = with config.lib.stylix.colors.withHashtag; [
          "16=${base09}"
          "17=${base0F}"
          "18=${base01}"
          "19=${base02}"
          "20=${base04}"
          "21=${base06}"
        ];
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
