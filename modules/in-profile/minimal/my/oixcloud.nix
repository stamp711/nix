{ lib, self, ... }:
let
  # Everything a caller sets on either platform.
  oixcloudOptions = lib: {
    enable = lib.mkEnableOption "the oixCloud external-proxy helper";
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
    udpAdvertiseAddress = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        IPv4 address clients send UDP relay packets to, which upstream will not
        infer. Null leaves the relay on ephemeral ports, and from v0.0.32 remote
        SOCKS5 nodes then advertise themselves TCP-only.
      '';
    };
    udpBasePort = lib.mkOption {
      type = lib.types.port;
      default = 10000;
      description = "First port of the UDP relay range; upstream's example value.";
    };
    udpPortCount = lib.mkOption {
      type = lib.types.ints.positive;
      default = 100;
      description = ''
        UDP relay ports from {option}`my.oixcloud.udpBasePort` upwards. One is held
        per association rather than per node, so this bounds concurrent UDP flows.
      '';
    };
    tokenFile = lib.mkOption {
      # Under home-manager agenix hands out a path that only a shell can resolve.
      type = lib.types.str;
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
              type = lib.types.str;
              description = "Decrypted file holding the Basic auth password.";
            };
          };
        }
      );
    };
  };

  templateName = "oixcloud.json";

  # Upstream's config.json, as one my.age-template entry.
  templateFile = cfg: {
    placeholders = lib.mkMerge [
      { accessToken = cfg.tokenFile; }
      (lib.mkIf (cfg.lanAuth != null) { lanPassword = cfg.lanAuth.passwordFile; })
    ];
    content = builtins.toJSON (
      self.lib.mergeDisjoint [
        {
          accessToken = "$accessToken";
          # Upstream's default, spelled out because mapBasePort and the firewall assume it.
          proxyMode = "map";
          servePort = cfg.port;
          inherit (cfg) mapBasePort;
          listenAddress = "0.0.0.0";
        }
        (lib.optionalAttrs (cfg.lanAuth != null) {
          lanAuth = {
            inherit (cfg.lanAuth) username;
            password = "$lanPassword";
          };
        })
        (lib.optionalAttrs (cfg.udpAdvertiseAddress != null) {
          inherit (cfg) udpAdvertiseAddress;
          udpPortRange = {
            start = cfg.udpBasePort;
            end = cfg.udpBasePort + cfg.udpPortCount - 1;
          };
        })
      ]
    );
  };
in
{
  flake.nixosModules.my =
    { config, ... }:
    let
      cfg = config.my.oixcloud;
    in
    {
      options.my.oixcloud = self.lib.mergeDisjoint [
        (oixcloudOptions lib)
        {
          openFirewall = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Open the serve and node ports in the firewall.";
          };
        }
      ];

      config = lib.mkIf cfg.enable (
        let
          image = self.lib.oixcloudImage;
          dataDir = "/var/lib/oixcloud";
          uid = "10001"; # The unprivileged id the image runs as
          lastMapPort = cfg.mapBasePort + cfg.mapPortCount - 1;
          lastUdpPort = cfg.udpBasePort + cfg.udpPortCount - 1;
          udpRelay = cfg.udpAdvertiseAddress != null;
          template = config.my.age-template.files.${templateName};
        in
        {
          my.age-template.files.${templateName} = lib.mkMerge [
            (templateFile cfg)
            {
              owner = uid;
              group = uid;
            }
          ];

          # The data directory when my.persistence is off, which creates it otherwise.
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
            allowedUDPPortRanges = lib.optionals udpRelay [
              {
                from = cfg.udpBasePort;
                to = lastUdpPort;
              }
            ];
          };

          # The bind mount pins the inode it started with, so a running container keeps
          # reading the old config until something restarts it.
          systemd.services.podman-oixcloud.restartTriggers = [ template.renderedFileHash ];

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
            ]
            ++ lib.optional udpRelay "${toString cfg.udpBasePort}-${toString lastUdpPort}:${toString cfg.udpBasePort}-${toString lastUdpPort}/udp";
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
        }
      );
    };

  # Darwin runs upstream's macOS build.
  flake.homeModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.oixcloud;
    in
    {
      options.my.oixcloud = oixcloudOptions lib;

      config = lib.mkIf cfg.enable (
        let
          template = config.my.age-template.files.${templateName};
          # Upstream's default config file location.
          configName = "oixcloud-external-proxy-program/config.json";
        in
        {
          # This home module builds upstream's macOS binary; elsewhere it is a mistake.
          assertions = [
            {
              assertion = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
              message = "my.oixcloud: this home module is for aarch64-darwin.";
            }
          ];

          my.age-template.files.${templateName} = templateFile cfg;
          xdg.configFile.${configName}.source = config.lib.file.mkOutOfStoreSymlink template.path;

          launchd.agents.oixcloud = {
            enable = true;
            config = rec {
              ProgramArguments =
                let
                  start = pkgs.writeShellApplication {
                    name = "oixcloud-start";
                    runtimeInputs = [ self.packages.${pkgs.stdenv.hostPlatform.system}.oixcloud ];
                    # Rendered here because launchd cannot order us after the age-template
                    # agent. Rendering twice costs nothing.
                    text = ''
                      ${template.renderScript}
                      exec oixcloud-external-proxy-program \
                        --serve --mode map \
                        --listen 0.0.0.0:${toString cfg.port} \
                        --bind 0.0.0.0 \
                        --config ${config.xdg.configHome}/${configName}
                    '';
                  };
                in
                [ "${start}/bin/oixcloud-start" ];
              WorkingDirectory = config.home.homeDirectory; # launchd defaults to "/"
              KeepAlive = true;
              RunAtLoad = true;
              # launchd sends both streams to /dev/null without these.
              StandardOutPath = "${config.home.homeDirectory}/Library/Logs/oixcloud.log";
              StandardErrorPath = StandardOutPath;
            };
          };
        }
      );
    };
}
