{
  description = "EFI + BTRFS disk layout (systemd-boot, ESP + BTRFS subvolumes)";

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

      options.boot-disk.device = lib.mkOption {
        type = lib.types.str;
      };

      config = {
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
                    "@swap".swap.swapfile.size = "16G";
                  };
                };
              };
            };
          };
        };
      };
    };
}
