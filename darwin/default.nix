{
  pkgs,
  lib,
  ...
}: {
  system.stateVersion = 4;
  programs.zsh.enable = true;

  imports = [./homebrew.nix];

  programs.nix-index.enable = true;

  services.nix-daemon.enable = true;
  nix.settings = {
    # auto-optimise-store = true; # https://github.com/NixOS/nix/issues/7273
    trusted-users = ["@admin"];
  };
  nix.extraOptions =
    ''
      experimental-features = nix-command flakes
    ''
    + lib.optionalString (pkgs.system == "aarch64-darwin") ''
      extra-platforms = x86_64-darwin aarch64-darwin
    '';

  system.defaults.NSGlobalDomain = {
    # AppleFontSmoothing = 0;
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
    NSAutomaticSpellingCorrectionEnabled = false;
  };
}
