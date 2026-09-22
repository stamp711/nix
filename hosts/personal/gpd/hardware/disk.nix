{
  flake.nixosModules.gpd = {

    my.boot-disk = {
      enable = true;
      layout.efi-btrfs = {
        device = "/dev/nvme0n1";
        luks = true;
        swapSize = "32G";
      };
    };

  };
}
