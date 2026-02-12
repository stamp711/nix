{
  description = "BTRFS disk layout with disko (ESP + BTRFS subvolumes)";

  module =
    { inputs, ... }:
    {
      imports = [ inputs.disko.nixosModules.disko ];

      disko.devices.disk.main = {
        device = "/dev/nvme0n1";
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
                extraArgs = [ "-f" ]; # Override existing partition
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
}
