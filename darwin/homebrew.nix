{...}: {
  homebrew = {
    enable = true;
    brews = [];
    casks = [
      "kitty"
    ];
    taps = [
      "buo/cask-upgrade"
      "homebrew/cask-fonts"
    ];
  };
}
