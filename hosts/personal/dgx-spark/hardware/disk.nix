{
  flake.nixosModules.dgx-spark = {

    my.boot-disk = {
      enable = true;
      layout.efi-btrfs = {
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZALC4T0HBL1-00B07_S8C2NG0Y912984";
        luks = false;
      };
    };

  };
}
