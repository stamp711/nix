{
  flake.nixosModules.nuc =
    { pkgs, ... }:
    {

      my.boot-disk = {
        enable = true;
        layout.efi-btrfs = {
          device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_1TB_S6Z1NJ0W395410E";
          luks = true;
          swapSize = "16G";
        };
      };

      boot.loader.systemd-boot.windows."11" = {
        title = "Windows 11";
        efiDeviceHandle = "HD2b";
      };

      environment.systemPackages = [
        (pkgs.writeShellScriptBin "reboot-windows" ''
          exec systemctl reboot --boot-loader-entry=windows_11.conf
        '')
      ];

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

      # Windows D: drive.
      fileSystems."/mnt/d" = {
        device = "/dev/disk/by-uuid/D040534940533606";
        fsType = "ntfs3";
        options = [
          "uid=1000"
          "gid=100"
          "umask=022"
          "iocharset=utf8"
          "windows_names"
          "noatime"
          "discard"
          "prealloc"
          "nofail"
          "x-systemd.device-timeout=5"
          "x-gvfs-show"
        ];
      };

    };
}
