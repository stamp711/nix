{ lib, ... }:
{
  flake.nixosModules.nuc = lib.mkMerge [
    {
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
    }

    # Bind mounts keeping the D: drive library's Proton prefixes and shader cache off NTFS.
    # NTFS windows_names can't hold dosdevices/c:
    (
      { config, ... }:
      let
        user = config.my.primaryUser;
        group = config.users.users.${user}.group;

        library = "/mnt/d/SteamLibrary/steamapps";

        compatdata = "/var/lib/steam/compatdata";
        shadercache = "/var/lib/steam/shadercache";
      in
      {
        my.persistence.directories = [
          {
            directory = compatdata;
            inherit user group;
            mode = "0755";
          }
          {
            directory = shadercache;
            inherit user group;
            mode = "0755";
          }
        ];
        fileSystems = {
          "${library}/compatdata" = {
            device = compatdata;
            fsType = "none";
            options = [
              "bind"
              "nofail"
            ];
            depends = [
              "/mnt/d"
              compatdata
            ];
          };
          "${library}/shadercache" = {
            device = shadercache;
            fsType = "none";
            options = [
              "bind"
              "nofail"
            ];
            depends = [
              "/mnt/d"
              shadercache
            ];
          };
        };
      }
    )

  ];
}
