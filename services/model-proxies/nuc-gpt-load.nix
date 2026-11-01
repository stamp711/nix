{ lib, ... }:
{
  flake.nixosModules.nuc =
    { pkgs, ... }:
    {
      users.users.gpt-load = {
        isSystemUser = true;
        group = "gpt-load";
      };
      users.groups.gpt-load = { };

      systemd.services.gpt-load = {
        description = "GPT-Load AI gateway";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          HOST = "127.0.0.1";
          PORT = "3001";
          DATA_DIR = "/var/lib/gpt-load";
        };
        serviceConfig = {
          ExecStart = lib.getExe pkgs.my.gpt-load;
          User = "gpt-load";
          StateDirectory = "gpt-load";
          StateDirectoryMode = "0700";
          Restart = "on-failure";
        };
      };

      # Includes the database and generated auth.key and encryption.key.
      my.persistence.directories = [ "/var/lib/gpt-load" ];

      services.traefik.dynamicConfigOptions.http = {
        routers.gpt-load = {
          rule = "Host(`gpt-load.nuc.apric.net`)";
          service = "gpt-load";
        };
        services.gpt-load.loadBalancer.servers = [
          { url = "http://127.0.0.1:3001"; }
        ];
      };
    };
}
