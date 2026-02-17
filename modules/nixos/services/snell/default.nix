{
  description = "Snell proxy server";

  module =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.services.snell;
    in
    {
      options.services.snell = {
        enable = lib.mkEnableOption "Snell proxy server";
        port = lib.mkOption {
          type = lib.types.port;
        };
        pskSecretFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to .age file containing the Snell PSK";
        };
      };

      config = lib.mkIf cfg.enable {
        age.secrets.snell-psk.rekeyFile = cfg.pskSecretFile;
        age-template.files."snell.conf" = {
          vars.psk = config.age.secrets.snell-psk.path;
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
            LoadCredential = "config:${config.age-template.files."snell.conf".path}";
            DynamicUser = true;
            NoNewPrivileges = true;
          };
        };

        networking.firewall.allowedTCPPorts = [ cfg.port ];
      };
    };
}
