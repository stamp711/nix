{
  flake.nixosModules.my =
    { config, lib, ... }:
    let
      cfg = config.my.oixcloud;
      image = "ghcr.io/pickrui/oixcloud-external-proxy-program@sha256:f1f219733cc19a502a59d4e27435e42475f66c4f19a3cdf986f3deac054ca329";
      dataDir = "/var/lib/oixcloud";
      uid = "10001"; # The unprivileged id the image runs as
      lastMapPort = cfg.mapBasePort + cfg.mapPortCount - 1;
      templateName = "oixcloud.json";
      template = config.my.age-template.files.${templateName};
    in
    {
      options.my.oixcloud = {
        enable = lib.mkEnableOption "the oixCloud external-proxy helper";
        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Open the serve and node ports in the firewall.";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 6172;
          description = "Port serving the config, node list and health endpoints.";
        };
        mapBasePort = lib.mkOption {
          type = lib.types.port;
          default = 7200;
          description = "First port of the node mapping range.";
        };
        mapPortCount = lib.mkOption {
          type = lib.types.ints.positive;
          default = 100;
          description = "Node mapping ports from {option}`my.oixcloud.mapBasePort` upwards.";
        };
        tokenFile = lib.mkOption {
          type = lib.types.path;
          description = "Decrypted file holding the account's accessToken, nothing else.";
        };
        lanAuth = lib.mkOption {
          default = null;
          description = ''
            HTTP Basic credentials. Null serves unauthenticated, which upstream
            only considers safe because these URLs are plain HTTP on a trusted LAN.
          '';
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                username = lib.mkOption {
                  type = lib.types.str;
                  description = "Basic auth username.";
                };
                passwordFile = lib.mkOption {
                  type = lib.types.path;
                  description = "Decrypted file holding the Basic auth password.";
                };
              };
            }
          );
        };
      };

      config = lib.mkIf cfg.enable {
        my.age-template.files.${templateName} = {
          vars = lib.mkMerge [
            { accessToken = cfg.tokenFile; }
            (lib.mkIf (cfg.lanAuth != null) { lanPassword = cfg.lanAuth.passwordFile; })
          ];
          owner = uid;
          group = uid;
          content = builtins.toJSON (
            {
              accessToken = "$accessToken";
              proxyMode = "map";
              servePort = cfg.port;
              inherit (cfg) mapBasePort;
              listenAddress = "0.0.0.0";
              simpleRules = false;
            }
            // lib.optionalAttrs (cfg.lanAuth != null) {
              lanAuth = {
                inherit (cfg.lanAuth) username;
                password = "$lanPassword";
              };
            }
          );
        };

        # Redundant wherever my.persistence is on; it is what creates the dir elsewhere.
        systemd.tmpfiles.rules = [ "d ${dataDir} 0700 ${uid} ${uid} - -" ];
        my.persistence.directories = [
          {
            directory = dataDir;
            user = uid;
            group = uid;
            mode = "0700";
          }
        ];

        networking.firewall = lib.mkIf cfg.openFirewall {
          allowedTCPPorts = [ cfg.port ];
          allowedTCPPortRanges = [
            {
              from = cfg.mapBasePort;
              to = lastMapPort;
            }
          ];
        };

        virtualisation.oci-containers.containers.oixcloud = {
          inherit image;
          cmd = [
            "--map"
            "--listen"
            "0.0.0.0:${toString cfg.port}"
            "--bind"
            "0.0.0.0"
            "--config"
            "/config/config.json"
          ];
          ports = [
            "${toString cfg.port}:${toString cfg.port}/tcp"
            "${toString cfg.mapBasePort}-${toString lastMapPort}:${toString cfg.mapBasePort}-${toString lastMapPort}/tcp"
          ];
          volumes = [
            "${template.path}:/config/config.json:ro"
            "${dataDir}:/data"
          ];
          # Upstream's compose.yaml hardening, kept verbatim.
          extraOptions = [
            "--user=${uid}:${uid}"
            "--read-only"
            "--cap-drop=ALL"
            "--security-opt=no-new-privileges:true"
            "--tmpfs=/tmp:rw,noexec,nosuid,size=16m"
            "--init"
          ];
        };

      };
    };
}
