{
  flake.nixosModules.linux-gaming =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
        gamescopeSession.enable = true;
        # -steamdeck unlocks Deck UI surface and steamdeck_stable channel.
        gamescopeSession.steamArgs = [
          "-steamdeck"
          "-steamos3"
          "-gamepadui"
          "-pipewire-dmabuf"
        ];
        protontricks.enable = true;
        extest.enable = true;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        extraPackages = [
          # Big Picture's "Switch to Desktop" exec's this; -shutdown exits
          # steam cleanly, which ends gamescope, returning to greetd.
          (pkgs.writeShellScriptBin "steamos-session-select" ''
            exec steam -shutdown
          '')
          # mangoapp for Big Picture's performance overlay.
          pkgs.mangohud
        ];
      };
    };
}
