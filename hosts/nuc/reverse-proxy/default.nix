{ self, ... }:
{
  flake.nixosModules.nuc =
    { config, ... }:
    let
      tunnelId = "b2cf7941-2ee4-4aab-bba6-3b261a13460b";
      tunnelCredentials = self.lib.mkAgeSecret config { rekeyFile = ./credentials.json.age; };
    in
    {
      # Cloudflare Tunnel.
      age.secrets = tunnelCredentials.ageSecret;

      services.cloudflared = {
        enable = true;
        tunnels.${tunnelId} = {
          credentialsFile = tunnelCredentials.path;
          protocol = "http2";
          edgeIPVersion = "auto";
          default = "http_status:404"; # managed by dashboard
        };
      };
      systemd.services."cloudflared-tunnel-${tunnelId}".restartTriggers = [ ./credentials.json.age ];

      # HTTP entry points.
      services.traefik = {
        enable = true;
        staticConfigOptions.entryPoints = {
          web.address = ":80";
          tunnel = {
            address = "127.0.0.1:18080";
            forwardedHeaders.trustedIPs = [ "127.0.0.1/32" ];
          };
        };
      };
    };
}
