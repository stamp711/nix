# NUC13RNGi9 hardware (Intel i9-13900, Intel iGPU + NVIDIA RTX 4080)
{ inputs, ... }:
{
  flake.nixosModules.nuc-hardware =
    {
      config,
      pkgs,
      ...
    }:
    let
      # Shared core sequence: modprobe cycle + FLR + settle + persistence mode.
      # Boot service exec's it directly. PAM hook wraps with PAM_USER guard
      # and journal redirect before exec'ing it.
      nvidiaReset = pkgs.writeShellScript "nvidia-reset" ''
        echo "nvidia-reset: start"
        ${pkgs.kmod}/bin/modprobe -r nvidia_uvm nvidia_drm nvidia_modeset nvidia
        echo "nvidia-reset: modprobe -r exit=$?"
        ${pkgs.kmod}/bin/modprobe nvidia_drm
        echo "nvidia-reset: modprobe load exit=$?"
        ${config.hardware.nvidia.package.bin}/bin/nvidia-smi --gpu-reset
        echo "nvidia-reset: --gpu-reset exit=$?"
        ${pkgs.systemd}/bin/udevadm settle --timeout=5
        echo "nvidia-reset: udevadm settle exit=$?"
        ${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pm 1
        echo "nvidia-reset: -pm 1 exit=$?"
        echo "nvidia-reset: done"
      '';
    in
    {
      imports = [
        inputs.nixos-hardware.nixosModules.common-gpu-intel
        inputs.nixos-hardware.nixosModules.common-pc-ssd
      ];
      hardware.cpu.intel.updateMicrocode = true;

      # Set intel_pstate EPP value to 64 (default 128)
      # Disable power-profiles-daemon from GNOME
      services.power-profiles-daemon.enable = false;
      boot.kernel.sysfs.devices.system.cpu."cpu[0-9]*".cpufreq.energy_performance_preference = 64;

      # Intel iGPU for host display
      hardware.graphics.enable = true;

      # NVIDIA proprietary driver with open kernel module
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia.open = true;
      hardware.nvidia.modesetting.enable = true;

      # Reset NVIDIA driver state at boot for a fresh DRM handoff.
      # Ordered before display-manager and persistenced so nothing's holding modules yet.
      # Ref: https://github.com/ValveSoftware/gamescope/issues/1593#issuecomment-4150595049
      systemd.services.nvidia-reset = {
        description = "Reset NVIDIA driver state before display services";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-modules-load.service" ];
        before = [
          "display-manager.service"
          "nvidia-persistenced.service"
        ];
        # Boot-only, definition changes take effect on next boot.
        restartIfChanged = false;
        stopIfChanged = false;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = "exec ${nvidiaReset}";
      };

      # Same reset before each greetd login; covers logout/re-login flicker.
      # Ref: https://github.com/ValveSoftware/gamescope/issues/1593#issuecomment-4150595049
      security.pam.services.greetd.rules.session.nvidia-reset = {
        control = "optional";
        modulePath = "${pkgs.linux-pam}/lib/security/pam_exec.so";
        args = [
          "${pkgs.writeShellScript "nvidia-reset-pam" ''
            case "$PAM_USER" in
              greeter|"") exit 0 ;;
            esac
            exec > >(${pkgs.systemd}/bin/systemd-cat) 2>&1
            exec ${nvidiaReset}
          ''}"
        ];
        order = 11000;
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

      # Disable Energy Efficient Ethernet on igc NIC to prevent link flapping
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="net", DRIVERS=="igc", RUN+="${pkgs.ethtool}/bin/ethtool --set-eee $name eee off"
      '';

      my.boot-disk = {
        enable = true;
        layout = "efi-luks-btrfs";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_1TB_S6Z1NJ0W395410E";
        swapSize = "16G";
      };

      boot.loader.systemd-boot.windows."11" = {
        title = "Windows 11";
        efiDeviceHandle = "HD2b";
      };

      # Keep Windows Boot Manager NVRAM entry inactive so it doesn't self-promote.
      # https://www.yhi.moe/blog/en/preventing-windows-from-modifying-your-uefi-boot-sequence
      systemd.services.deactivate-windows-boot-entry = {
        description = "Deactivate Windows Boot Manager NVRAM entry";
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.efibootmgr ];
        serviceConfig.Type = "oneshot";
        script = ''
          efibootmgr | grep -E '^Boot[0-9A-Fa-f]{4}\* Windows Boot Manager' | while read -r line; do
            num="''${line:4:4}"
            echo "Deactivating: $line"
            efibootmgr --bootnum "$num" --inactive
          done
        '';
      };

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "ahci"
        "thunderbolt"
        "tpm_crb"
      ];

      boot.kernelParams = [
        "intel_iommu=on"
        "iommu=pt"
      ];
    };
}
