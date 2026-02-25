{
  description = "Xray proxy with Caddy reverse proxy";

  module =
    {
      self,
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.xray-proxy;
      secretNames = map self.lib.ageSecretName cfg.secretEnvFiles;
      decryptedPaths = map (n: config.age.secrets.${n}.path) secretNames;
    in
    {
      options.my.xray-proxy = {
        enable = lib.mkEnableOption "Xray proxy with Caddy";
        openFirewall = lib.mkEnableOption "Open TCP port 443 in the firewall";
        secretEnvFiles = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          description = "List of .age env files containing DOMAIN, CAMOUFLAGE, UUIDs, passwords, and paths";
        };
      };

      config = lib.mkIf cfg.enable {
        age.secrets = lib.listToAttrs (
          lib.zipListsWith (name: file: {
            inherit name;
            value.rekeyFile = file;
          }) secretNames cfg.secretEnvFiles
        );

        # Caddy
        my.age-template.files."Caddyfile" = {
          envFiles = decryptedPaths;
          content = builtins.readFile ./Caddyfile.template;
          owner = "caddy";
          group = "caddy";
        };
        services.caddy = {
          enable = true;
          configFile = config.my.age-template.files."Caddyfile".path;
        };
        systemd.services.caddy.reloadTriggers = [ ./Caddyfile.template ] ++ cfg.secretEnvFiles;

        # Xray
        my.age-template.files."xray-config.json" = {
          envFiles = decryptedPaths;
          content = builtins.readFile ./xray-config.json.template;
        };
        services.xray = {
          enable = true;
          settingsFile = config.my.age-template.files."xray-config.json".path;
        };
        systemd.services.xray.restartTriggers = [ ./xray-config.json.template ] ++ cfg.secretEnvFiles;

        # Firewall
        networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 443 ];
      };
    };
}
