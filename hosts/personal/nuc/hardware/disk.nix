{
  flake.nixosModules.nuc = {

    my.boot-disk = {
      enable = true;
      layout.efi-btrfs = {
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_1TB_S6Z1NJ0W395410E";
        luks = true;
        swapSize = "16G";
      };
    };

    my.windows-dual-boot = {
      enable = true;
      efiDeviceHandle = "HD2b";
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
