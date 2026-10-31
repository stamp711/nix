{
  flake.nixosModules.nuc =
    { config, ... }:
    {
      services.traefik.dynamicConfigOptions.http = {
        routers.cpa-cf = {
          entryPoints = [ "tunnel" ];
          rule = "Host(`cpa.apric.net`)";
          service = "cpa";
        };
        routers.cpa = {
          rule = "Host(`cpa.nuc.apric.net`)";
          service = "cpa";
        };
        services.cpa.loadBalancer.servers = [
          { url = "http://127.0.0.1:${toString config.services.cliproxyapi.settings.port}"; }
        ];
      };
    };
}
