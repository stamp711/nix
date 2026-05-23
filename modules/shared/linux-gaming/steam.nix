{
  flake.nixosModules.linux-gaming =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
        gamescopeSession.enable = true;
        # New SteamOS3/GamepadUI; default is the older -tenfoot Big Picture.
        gamescopeSession.steamArgs = [
          "-steamos3"
          "-gamepadui"
          "-pipewire-dmabuf"
        ];
        protontricks.enable = true;
        extest.enable = true;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        # Big Picture's "Switch to Desktop" exec's this; -shutdown exits
        # steam cleanly, which ends gamescope, returning to greetd.
        extraPackages = [
          (pkgs.writeShellScriptBin "steamos-session-select" ''
            exec steam -shutdown
          '')
        ];
      };
    };
}
