{
  description = "EFI + LUKS2 + BTRFS disk layout (systemd-boot, encrypted root with BTRFS subvolumes)";

  module =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      cfg = config.boot-disk;
    in
    {
      imports = [ inputs.disko.nixosModules.disko ];

      options.boot-disk = {
        device = lib.mkOption {
          type = lib.types.str;
        };
        swapSize = lib.mkOption {
          type = lib.types.str;
          default = "16G";
        };
      };

      config = {
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
      };
    };
}
