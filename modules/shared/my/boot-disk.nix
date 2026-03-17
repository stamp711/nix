{
  flake.nixosModules.my =
    { lib, config, ... }:
    let
      cfg = config.my.boot-disk;

      espPartition = {
        size = "1G";
        type = "EF00";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = [ "umask=0077" ];
        };
      };

      btrfsContent = {
        type = "btrfs";
        mountOptions = [
          "noatime"
          "ssd"
          "compress=zstd:3"
          "space_cache=v2"
          "discard=async"
        ];
        extraArgs = [ "-f" ];
        subvolumes = {
          "@root".mountpoint = "/";
          "@nix".mountpoint = "/nix";
          "@home".mountpoint = "/home";
          "@swap".mountpoint = "/.swap";
          "@swap".swap.swapfile.size = cfg.swapSize;
        };
      };
    in
    {
      options.my.boot-disk = {
        enable = lib.mkEnableOption "declarative disk layout via disko";
        layout = lib.mkOption {
          type = lib.types.enum [
            "efi-btrfs"
            "efi-luks-btrfs"
            "mbr-ext4"
          ];
        };
        device = lib.mkOption {
          type = lib.types.str;
        };
        swapSize = lib.mkOption {
          type = lib.types.str;
          default = "16G";
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [

          # efi-btrfs layout
          (lib.mkIf (cfg.layout == "efi-btrfs") {
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            disko.devices.disk.main = {
              inherit (cfg) device;
              type = "disk";
              content = {
                type = "gpt";
                partitions.ESP = espPartition;
                partitions.root = {
                  size = "100%";
                  content = btrfsContent;
                };
              };
            };
          })

          # efi-luks-btrfs layout
          (lib.mkIf (cfg.layout == "efi-luks-btrfs") {
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            boot.initrd.systemd.enable = true;
            disko.devices.disk.main = {
              inherit (cfg) device;
              type = "disk";
              content = {
                type = "gpt";
                partitions.ESP = espPartition;
                partitions.root = {
                  size = "100%";
                  content = {
                    type = "luks";
                    name = "cryptroot";
                    settings.allowDiscards = true;
                    content = btrfsContent;
                  };
                };
              };
            };
          })

          # mbr-ext4 layout
          (lib.mkIf (cfg.layout == "mbr-ext4") {
            boot.loader.grub.enable = true;
            disko.devices.disk.main = {
              inherit (cfg) device;
              type = "disk";
              content = {
                type = "gpt";
                partitions.boot = {
                  size = "1M";
                  type = "EF02";
                };
                partitions.root = {
                  size = "100%";
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";
                  };
                };
              };
            };
          })

        ]
      );
    };
}
