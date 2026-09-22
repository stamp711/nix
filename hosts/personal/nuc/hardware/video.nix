{
  flake.nixosModules.nuc =
    { pkgs, ... }:
    {

      # Intel iGPU for host display
      hardware.graphics.enable = true;

      # NVIDIA proprietary driver with open kernel module
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia.open = true;
      hardware.nvidia.modesetting.enable = true;

      # Turn off NVIDIA GPU's on-card LED
      systemd.services.gpu-led-off = {
        wantedBy = [ "graphical.target" ];
        after = [ "graphical.target" ];
        serviceConfig.Type = "oneshot";
        # openrgb writes config+logs to cwd; scratch dir it
        serviceConfig.RuntimeDirectory = "gpu-led-off";
        serviceConfig.WorkingDirectory = "%t/gpu-led-off";
        serviceConfig.ProtectSystem = "strict"; # ro elsewhere
        # OpenRGB sometimes segfaults during the scan. Loop as a workaround for now.
        script = ''
          for attempt in 1 2 3 4 5; do
            if ${pkgs.openrgb}/bin/openrgb --noautoconnect --device NVIDIA --mode Off; then
              exit 0
            fi

            if [ "$attempt" -lt 5 ]; then
              echo "OpenRGB failed on attempt $attempt; retrying"
              ${pkgs.coreutils}/bin/sleep 2
            fi
          done

          echo "OpenRGB failed after 5 attempts"
          exit 1
        '';
      };

      # LG OLED needs --immediate-flips to avoid flickr; 165Hz from EDID DisplayID block.
      programs.steam.gamescopeSession.args = [
        "--adaptive-sync"
        "--immediate-flips"
        "--hdr-enabled"
        "--output-width"
        "3840"
        "--output-height"
        "2160"
        "--nested-refresh"
        "165"
      ];

    };
}
