{ lib, self, ... }:
let
  port = 8317;
in
{
  # Official models, including codex-auto-review, use maintained catalog snapshots.
  modelProxies.cliproxyapi.baseUrl = "http://nuc.boar-char.ts.net:${toString port}/v1";

  flake.nixosModules.nuc =
    { config, pkgs, ... }:
    let
      cfg = config.services.cliproxyapi;
      configFile = (pkgs.formats.yaml { }).generate "cliproxyapi.yaml" cfg.settings;
      configPath = "/etc/cliproxyapi/config.yaml";
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
          auth-dir = "/var/lib/cliproxyapi/auth";
          # Preserve upstream rate-limit and Codex session/catalog headers.
          passthrough-headers = true;
          # Let the client choose tools; do not inject image_generation.
          disable-image-generation = "passthrough";
        };
      };

      environment.etc."cliproxyapi/config.yaml".source = configFile;
      systemd.services.cliproxyapi = {
        # ProtectSystem=strict makes /etc read-only; StateDirectory stays writable.
        environment.MANAGEMENT_STATIC_PATH = "/var/lib/cliproxyapi/static";
        # Upstream otherwise generates a writable copy in its state directory.
        preStart = lib.mkForce "";
        serviceConfig.ExecStart = lib.mkForce "${lib.getExe cfg.package} -config ${configPath}";
        restartTriggers = [ configFile ];
      };

      # The service's StateDirectory sets ownership and mode 0700 before startup.
      my.persistence.directories = [ "/var/lib/cliproxyapi" ];
      environment.systemPackages = [ cfg.package ];
    };
}
