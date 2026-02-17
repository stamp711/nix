{
  description = "MBR + ext4 disk layout (GRUB)";

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
      };
    };
}
