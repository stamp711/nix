{ pkgs, lib, ... }: {
  programs.zsh.enable = true;
  system.stateVersion = 4;

  users.users.stamp = { home = "/Users/stamp"; };

  services.nix-daemon.enable = true;
  nix.settings = {
    auto-optimise-store = true;
    trusted-users = [ "@admin" ];
  };
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '' + lib.optionalString (pkgs.system == "aarch64-darwin") ''
    extra-platforms = x86_64-darwin aarch64-darwin
  '';
}
