{ inputs, ... }:
{
  flake.nixosModules.nuc =
    { config, ... }:
    {
      imports = [ inputs.nixarr.nixosModules.default ];

      nixarr = {
        enable = true;
        mediaDir = "/mnt/nas/Library/Nixarr";
        stateDir = "/var/lib/nixarr";
        mediaUsers = [ config.my.primaryUser ];
        komga.enable = true;
      };
      my.persistence.directories = [ config.nixarr.stateDir ];

      # Allow the media group to write to Library locally.
      my.smbMounts.nas.shares.Library.mountOptions = {
        gid = toString config.users.groups.media.gid;
        "x-systemd.idle-timeout" = "0";
      };

      # Komga proxy.
      services.traefik.dynamicConfigOptions.http = {
        routers.komga = {
          rule = "Host(`komga.nuc.apric.net`)";
          service = "komga";
        };
        services.komga.loadBalancer.servers = [
          { url = "http://127.0.0.1:${toString config.services.komga.settings.server.port}"; }
        ];
      };
    };
}
