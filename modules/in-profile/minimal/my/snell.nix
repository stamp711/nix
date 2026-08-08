{ lib, self, ... }:
{
  flake.nixosModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.snell;
    in
    {
      options.my.snell = {
        enable = lib.mkEnableOption "Snell proxy server";
        openFirewall = lib.mkEnableOption "Open the Snell port in the firewall";
        port = lib.mkOption {
          type = lib.types.port;
          description = "Port Snell listens on. No default: it should differ per host.";
        };
        pskSecretFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to .age file containing the Snell PSK";
        };
      };

      config = lib.mkIf cfg.enable (
        let
          secretName = self.lib.ageSecretName cfg.pskSecretFile;
        in
        {
          age.secrets.${secretName}.rekeyFile = cfg.pskSecretFile;

          my.age-template.files."snell.conf" = {
            placeholders.psk = config.age.secrets.${secretName}.path;
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
            # The port is in the rendered file too, and snell reads it once, through
            # LoadCredential, at start.
            restartTriggers = [ config.my.age-template.files."snell.conf".renderedFileHash ];
            serviceConfig = {
              ExecStart = "${pkgs.snell}/bin/snell-server -c %d/config";
              LoadCredential = "config:${config.my.age-template.files."snell.conf".path}";
              DynamicUser = true;
              NoNewPrivileges = true;
            };
          };

          networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
        }
      );
    };
}
