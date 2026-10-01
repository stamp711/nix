{
  flake.homeModules.desktop-linux = { pkgs, ... }: {
    home.packages = [ pkgs.chatgpt ];
  };

  flake.darwinModules.desktop-darwin = {
    homebrew.casks = [ "chatgpt" ];
  };
}
