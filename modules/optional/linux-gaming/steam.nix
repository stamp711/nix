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
        gamescopeSession.args = [
          # "--steam" hardcoded by nixpkgs's steam-gamescope wrapper.
          "--mangoapp"
          "--xwayland-count"
          "2"
          # Realtime scheduling via rtkit (enabled by audio.nix for pipewire).
          "--rt"
          # Use only EDID-listed modes rather than default CVT-synthesized timings.
          "--generate-drm-mode"
          "fixed"
          "--hide-cursor-delay"
          "3000"
          "--max-scale"
          "2"
          "--cursor-scale-height"
          "720"
          # Touchscreen passthrough; no-op on hosts without touch.
          "--default-touch-mode"
          "4"
        ];
        # Env exports cherry-picked from Valve's gamescope-session and ChimeraOS's
        # gamescope-session-plus. Steam reads STEAM_GAMESCOPE_*_SUPPORTED to expose
        # GamepadUI toggles for VRR / HDR / tearing / NIS / perf overlay; without
        # them the sliders don't appear.
        # https://github.com/Jovian-Experiments/PKGBUILDs-mirror/blob/jupiter-main/gamescope-3.16.23-3/gamescope-session
        # https://github.com/OpenGamingCollective/gamescope-session/blob/main/usr/share/gamescope-session-plus/gamescope-session-plus
        gamescopeSession.env = {
          STEAM_USE_MANGOAPP = "1";
          STEAM_MANGOAPP_PRESETS_SUPPORTED = "1";
          STEAM_MANGOAPP_HORIZONTAL_SUPPORTED = "1";
          STEAM_DISABLE_MANGOAPP_ATOM_WORKAROUND = "1";
          STEAM_GAMESCOPE_HDR_SUPPORTED = "1";
          STEAM_GAMESCOPE_VRR_SUPPORTED = "1";
          STEAM_GAMESCOPE_TEARING_SUPPORTED = "1";
          STEAM_GAMESCOPE_HAS_TEARING_SUPPORT = "1";
          STEAM_GAMESCOPE_NIS_SUPPORTED = "1";
          STEAM_GAMESCOPE_COLOR_MANAGED = "1";
          STEAM_GAMESCOPE_VIRTUAL_WHITE = "1";
          STEAM_GAMESCOPE_FANCY_SCALING_SUPPORT = "1";
          STEAM_GAMESCOPE_DYNAMIC_FPSLIMITER = "1";
          STEAM_GAMESCOPE_DYNAMIC_REFRESH_IN_STEAM_SUPPORTED = "0";
          ENABLE_GAMESCOPE_WSI = "1";
          # Per-game systemd scope
          STEAM_LAUNCH_WRAPPER_SCOPE = "1";
          # Pairs with --xwayland-count 2; isolates Steam popups from game focus.
          STEAM_MULTIPLE_XWAYLANDS = "1";
          # Steam handles XF86 volume keys (no desktop env in gamescope session).
          STEAM_ENABLE_VOLUME_HANDLER = "1";
          STEAM_ENABLE_STATUS_LED_BRIGHTNESS = "1";
          # Let wireplumber handle auto device switching
          STEAM_DISABLE_AUDIO_DEVICE_SWITCHING = "1";
          # Route Qt/GTK text input through Steam IME
          QT_IM_MODULE = "steam";
          GTK_IM_MODULE = "Steam";
          # Non-UI tweaks Valve ships
          vk_xwayland_wait_ready = "false";
          VKD3D_SWAPCHAIN_LATENCY_FRAMES = "3";
          WINEDLLOVERRIDES = "dxgi=n";
          SRT_URLOPEN_PREFER_STEAM = "1";
          SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS = "0";
          GAMESCOPE_NV12_COLORSPACE = "k_EStreamColorspace_BT601";
        };
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
