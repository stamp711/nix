{ lib, self, ... }:
{
  flake.nixosModules.nuc =
    { config, pkgs, ... }:
    let
      cfg = config.services.cliproxyapi;

      port = 8317;

      management = self.lib.mkAgeSecret config {
        rekeyFile = ./management.env.age;
        generator.script = { pkgs, ... }: ''
          printf 'MANAGEMENT_PASSWORD=%s\n' "$(${lib.getExe pkgs.openssl} rand -hex 32)"
        '';
      };

    in
    {
      age.secrets = management.ageSecret;

      services.cliproxyapi = {
        enable = true;
        package = pkgs.cli-proxy-api;
        # The management API requires a password even on localhost.
        environmentFile = management.path;
        # Internet traffic uses the LAN's transparent proxy.
        settings = {
          inherit port;
          host = "0.0.0.0";
          # Publish only prefixed backend IDs, avoiding duplicate model-picker entries.
          force-model-prefix = true;
          # OAuth login and refresh write credentials here, outside the config.
          oauth.auth-dir = "/var/lib/cliproxyapi/auth";
          # Preserve upstream rate-limit and Codex session/catalog headers.
          passthrough-headers = true;
          # Let the client choose tools; do not inject image_generation.
          disable-image-generation = "passthrough";
        };
      };

      # The service's StateDirectory sets ownership and mode 0700 before startup.
      my.persistence.directories = [ "/var/lib/cliproxyapi" ];
      environment.systemPackages = [ cfg.package ];

      services.traefik.dynamicConfigOptions.http = {
        routers.cpa = {
          rule = "Host(`cpa.nuc.apric.net`) || Host(`cpa.apric.net`)";
          service = "cpa";
        };
        services.cpa.loadBalancer.servers = [
          { url = "http://127.0.0.1:${toString cfg.settings.port}"; }
        ];
      };

    };
}
