{ self, ... }:
{
  flake.nixosModules.nuc =
    { config, ... }:
    let
      traefikEnv = self.lib.mkAgeSecret config { rekeyFile = ./env.age; };
    in
    {
      age.secrets = traefikEnv.ageSecret;

      services.traefik = {
        environmentFiles = [ traefikEnv.path ];
        dynamicConfigOptions.http = {
          routers.cpa = {
            entryPoints = [ "tunnel" ];
            rule = "Host(`{{ env `CPA_HOST` }}`) && PathPrefix(`/v1/`)";
            service = "cpa";
          };

          services.cpa.loadBalancer.servers = [
            {
              url = "http://127.0.0.1:${toString config.services.cliproxyapi.settings.port}";
            }
          ];
        };
      };

      systemd.services.traefik.restartTriggers = [ ./env.age ];
    };
}
