{ lib, self, ... }:
let
  # Everything a caller sets on either platform; only openFirewall is NixOS-only.
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
    tokenFile = lib.mkOption {
      # A path resolved at run time, which under home-manager only a shell can do.
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

  # Upstream's config.json, as one my.age-template entry: its `$name`s are the
  # placeholders, each filled from the file it is bound to.
  templateFile = cfg: {
    placeholders = lib.mkMerge [
      { accessToken = cfg.tokenFile; }
      (lib.mkIf (cfg.lanAuth != null) { lanPassword = cfg.lanAuth.passwordFile; })
    ];
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
in
{
  flake.nixosModules.my =
    { config, ... }:
    let
      cfg = config.my.oixcloud;
      image = self.lib.oixcloudImage;
      dataDir = "/var/lib/oixcloud";
      uid = "10001"; # The unprivileged id the image runs as
      lastMapPort = cfg.mapBasePort + cfg.mapPortCount - 1;
      template = config.my.age-template.files.${templateName};
    in
    {
      options.my.oixcloud = oixcloudOptions lib // {
        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Open the serve and node ports in the firewall.";
        };
      };

      config = lib.mkIf cfg.enable {
        my.age-template.files.${templateName} = lib.mkMerge [
          (templateFile cfg)
          {
            owner = uid;
            group = uid;
          }
        ];

        # Redundant where my.persistence is on; that is what creates the dir.
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

        # Nothing else would restart it: the bind mount holds the old inode open,
        # so a re-rendered config would never reach the running container.
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

  # Darwin runs upstream's macOS build; the container is Linux-only.
  flake.homeModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.oixcloud;
      template = config.my.age-template.files.${templateName};
      # Upstream's own location, linked to the rendered file. It is handed this
      # path, so whatever it puts beside its config stays in its own directory,
      # which we never wipe.
      configFile = "${config.xdg.configHome}/oixcloud-external-proxy-program/config.json";
      start = pkgs.writeShellApplication {
        name = "oixcloud-start";
        runtimeInputs = [ self.packages.${pkgs.stdenv.hostPlatform.system}.oixcloud ];
        # Render here, since launchd cannot order us after the age-template agent
        # and rendering is idempotent.
        text = ''
          ${template.renderScript}
          exec oixcloud-external-proxy-program \
            --serve --mode map \
            --listen 0.0.0.0:${toString cfg.port} \
            --bind 0.0.0.0 \
            --config ${configFile}
        '';
      };
    in
    {
      options.my.oixcloud = oixcloudOptions lib;

      config = lib.mkIf cfg.enable {
        # This home module builds upstream's macOS binary; elsewhere it is a mistake.
        assertions = [
          {
            assertion = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
            message = "my.oixcloud: this home module is for aarch64-darwin.";
          }
        ];

        my.age-template.files.${templateName} = templateFile cfg;

        xdg.configFile."oixcloud-external-proxy-program/config.json".source =
          config.lib.file.mkOutOfStoreSymlink template.path;

        launchd.agents.oixcloud = {
          enable = true;
          config = {
            ProgramArguments = [ "${start}/bin/oixcloud-start" ];
            WorkingDirectory = config.home.homeDirectory; # launchd defaults to "/"
            KeepAlive = true;
            RunAtLoad = true;
          };
        };
      };
    };
}
