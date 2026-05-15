# Parking lot: deferred items from review rounds. Revisit when actually needed.
# This file intentionally contributes no config.
{
  flake.nixosModules.linux-gaming = {
    # ---- mDNS / Avahi for VR headset discovery ----
    # WiVRn advertises via mDNS; Headset pairing may need this on
    # networks where the headset can't find the host by name.
    #   services.avahi = {
    #     enable = true;
    #     nssmdns4 = true;
    #     openFirewall = true;
    #     publish = { enable = true; userServices = true; addresses = true; };
    #   };

    # ---- Anti-cheat bootstrap libs ----
    # Some EAC games (Apex, Fortnite, Squad) need libkrb5/keyutils visible to Steam.
    #   programs.steam.extraPackages = pkgs: with pkgs; [ libkrb5 keyutils ];

    # ---- xdg portal for wlroots/Niri ----
    # Lutris/Heroic/Bottles filepicker crashes on pure wlroots without GTK portal.
    #   xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    # ---- Gamescope realtime ----
    # capSysNice is already set; --rt actually exercises it.
    #   programs.gamescope.args = [ "--rt" ];

    # ---- AppImage support ----
    # Heroic and several indie launchers ship as AppImage.
    #   programs.appimage.enable = true;
    #   programs.appimage.binfmt = true;

    # ---- envfs for modded games ----
    # Fills /usr/bin/env etc. so games with #!/usr/bin/python3 shebangs work
    # (KSP, RimWorld, Skyrim mods).
    #   services.envfs.enable = true;

    # ---- 8BitDo over Bluetooth ----
    # Fixes rumble / D-pad / battery reporting.
    #   hardware.xpadneo.enable = true;

    # ---- UDP buffers for VR streaming ----
    # ALVR/WiVRn benefit at >150 Mbps stream rates.
    #   boot.kernel.sysctl."net.core.rmem_max" = 67108864;
    #   boot.kernel.sysctl."net.core.wmem_max" = 67108864;

    # ---- WiVRn server tuning ----
    # Override encoder / bitrate / codec if defaults are bad.
    #   services.wivrn.config = {
    #     enable = true;
    #     json = { /* ... */ };
    #   };

    # ---- Intel iGPU VAAPI (NUC-specific) ----
    # OBS/Discord encode on iGPU while NVIDIA renders.
    #   hardware.graphics.extraPackages = with pkgs; [ intel-media-driver vpl-gpu-rt ];

    # ---- GPD handheld extras (gpd host only when added) ----
    #   services.handheld-daemon = { enable = true; user = "stamp"; };
    #   services.power-profiles-daemon.enable = true;  # opposite of NUC
    #   hardware.sensor.iio.enable = true;  # gyro for Steam Input

    # ---- Per-game env vars (Steam launch options, not declarative) ----
    # PROTON_ENABLE_NVAPI=1                        — DLSS/RTX via NVAPI
    # MANGOHUD=1                                   — overlay
    # gamescope -W 2880 -H 1700 -F fsr -- %command% — FSR upscaling
    # PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc
    #                                              — if non-Steam game can't see WiVRn socket
    # VR_OVERRIDE=${pkgs.xrizer}/lib/xrizer
    #                                              — force xrizer per-game when openvrpaths is on SteamVR
  };
}

# ---- Out-of-band manual steps not declared anywhere ----
# 1. Install SteamVR once via Steam (Tools → SteamVR) before ALVR sessions.
# 2. Sideload ALVR client.
# 3. Launch ALVR Linux server manually each session (no systemd unit).
# 4. After SteamVR/ALVR session, `home-manager switch` to restore openvrpaths → xrizer.
# 5. Add stamp to "input" group if a controller misbehaves under Steam Input.
