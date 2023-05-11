{...}: {
  homebrew = {
    enable = true;
    brews = [
      "koekeishiya/formulae/skhd"
      "koekeishiya/formulae/yabai"
    ];
    taps = [
      "buo/cask-upgrade"
      "homebrew/cask-fonts"
      "koekeishiya/formulae" # yabai & skhd
    ];
  };
}
