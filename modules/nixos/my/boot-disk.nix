{
  description = "Declarative boot disk layout via disko";

  module =
    { config, lib, ... }:
    let
      cfg = config.my.boot-disk;
    in
    {
      options.my.boot-disk = {
        enable = lib.mkEnableOption "declarative disk layout via disko";
        layout = lib.mkOption {
          type = lib.types.enum [
            "efi-btrfs"
            "efi-btrfs-luks"
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
                partitions = {
                  ESP = {
                    size = "1G";
                    type = "EF00";
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot";
                      mountOptions = [ "umask=0077" ];
                    };
                  };
                  root = {
                    size = "100%";
                    content = {
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
                  };
                };
              };
            };
          })

          # efi-btrfs-luks layout
          (lib.mkIf (cfg.layout == "efi-btrfs-luks") {
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            boot.initrd.systemd.enable = true;

            disko.devices.disk.main = {
              inherit (cfg) device;
              type = "disk";
              content = {
                type = "gpt";
                partitions = {
                  ESP = {
                    size = "1G";
                    type = "EF00";
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot";
                      mountOptions = [ "umask=0077" ];
                    };
                  };
                  root = {
                    size = "100%";
                    content = {
                      type = "luks";
                      name = "cryptroot";
                      settings.allowDiscards = true;
                      content = {
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
                    };
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
                partitions = {
                  boot = {
                    size = "1M";
                    type = "EF02";
                  };
                  root = {
                    size = "100%";
                    content = {
                      type = "filesystem";
                      format = "ext4";
                      mountpoint = "/";
                    };
                  };
                };
              };
            };
          })
        ]
      );
    };
}
