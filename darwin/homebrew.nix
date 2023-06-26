{...}: {
  homebrew = {
    enable = true;
    brews = [];
    casks = [
      "alacritty"
      "kitty"
    ];
    taps = [
      "buo/cask-upgrade"
      "homebrew/cask-fonts"
    ];
  };
}
