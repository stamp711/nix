{
  description = "Snell proxy server";

  module =
    {
      self,
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.my.snell;
      secretName = self.lib.ageSecretName cfg.pskSecretFile;
    in
    {
      options.my.snell = {
        enable = lib.mkEnableOption "Snell proxy server";
        openFirewall = lib.mkEnableOption "Open the Snell port in the firewall";
        port = lib.mkOption {
          type = lib.types.port;
        };
        pskSecretFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to .age file containing the Snell PSK";
        };
      };

      config = lib.mkIf cfg.enable {
        age.secrets.${secretName}.rekeyFile = cfg.pskSecretFile;
        my.age-template.files."snell.conf" = {
          vars.psk = config.age.secrets.${secretName}.path;
          content = ''
            [snell-server]
            listen = ::0:${toString cfg.port}
            psk = $psk
            ipv6 = true
          '';
        };
        systemd.services.snell = {
          description = "Snell Server";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          restartTriggers = [ cfg.pskSecretFile ];
          serviceConfig = {
            ExecStart = "${pkgs.snell}/bin/snell-server -c %d/config";
            LoadCredential = "config:${config.my.age-template.files."snell.conf".path}";
            DynamicUser = true;
            NoNewPrivileges = true;
          };
        };

        networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
      };
    };
}
