{
  flake.nixosModules.dgx-spark = {

    my.boot-disk = {
      enable = true;
      layout.efi-btrfs = {
        device = "/dev/nvme0n1";
        luks = false;
      };
    };

  };
}
