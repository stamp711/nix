{
  description = "Xray proxy with Caddy reverse proxy";

  module =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.services.xray-proxy;
    in
    {
      options.services.xray-proxy = {
        enable = lib.mkEnableOption "Xray proxy with Caddy";
        secretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to .age env file containing CAMOUFLAGE, UUIDs, passwords, and paths";
        };
      };

      config = lib.mkIf cfg.enable {
        age.secrets.xray-proxy.rekeyFile = cfg.secretsFile;

        # Caddy
        age-template.files."Caddyfile" = {
          envFiles = [ config.age.secrets.xray-proxy.path ];
          content = builtins.readFile ./Caddyfile.template;
          owner = "caddy";
          group = "caddy";
        };
        services.caddy = {
          enable = true;
          configFile = config.age-template.files."Caddyfile".path;
        };
        systemd.services.caddy.reloadTriggers = [
          ./Caddyfile.template
          cfg.secretsFile
        ];

        # Xray
        age-template.files."xray-config.json" = {
          envFiles = [ config.age.secrets.xray-proxy.path ];
          content = builtins.readFile ./xray-config.json.template;
        };
        services.xray = {
          enable = true;
          settingsFile = config.age-template.files."xray-config.json".path;
        };
        systemd.services.xray.restartTriggers = [
          ./xray-config.json.template
          cfg.secretsFile
        ];

        # Firewall
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];
      };
    };
}
