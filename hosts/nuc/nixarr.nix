{ inputs, lib, ... }:
{
  flake.nixosModules.nuc =
    {
      config,
      options,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.nixarr.nixosModules.default ];

      nixarr = {
        enable = true;
        mediaDir = "/mnt/nas/Library/Nixarr";
        stateDir = "/var/lib/nixarr";
        mediaUsers = [ config.my.primaryUser ];
        komga.enable = true;

        # Workaround 2026-10-28: remove once Nixarr includes the Jellyfin 12.4 API spec hash.
        nixarr-py.package = options.nixarr.nixarr-py.package.default.overridePythonAttrs {
          dependencies = pkgs.callPackage "${inputs.nixarr}/nixarr/lib/nixarr-py/python-deps.nix" {
            jellyfin = config.nixarr.jellyfin.package;
            fetchurl =
              args:
              pkgs.fetchurl (
                args
                //
                  lib.optionalAttrs
                    (args.url == "https://repo.jellyfin.org/files/openapi/stable/jellyfin-openapi-12.4.json")
                    {
                      hash = "sha256-AqYGSRa34I8fHY1//B+xx2I98ON4cp/Nf9NTdmhoA24=";
                    }
              );
          };
        };
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
