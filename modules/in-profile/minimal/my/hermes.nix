# Hermes Agent: upstream's gateway module plus the parts it leaves out, the backend server, and the web UI.
{ lib, inputs, ... }:
{
  flake.nixosModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.hermes;
    in
    {
      imports = [
        inputs.hermes-agent.nixosModules.default
        inputs.hermes-webui.nixosModules.default
      ];

      options.my.hermes = {
        enable = lib.mkEnableOption "the Hermes Agent gateway";
        environmentFiles = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = ''
            Env files merged into `$HERMES_HOME/.env` at activation. A provider API key
            belongs here: `hermes model` writes that same file, which activation
            truncates and rewrites on every switch.
          '';
        };
        serve = {
          enable = lib.mkEnableOption "the backend server the desktop app and TUI connect to";
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = ''
              Address `hermes serve` binds, upstream's default. Anything but loopback counts as
              public to hermes, which then demands {option}`my.hermes.serve.authFile` and exits 1
              without it.
            '';
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 9119;
            description = "Port for `hermes serve`.";
          };
          authFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = ''
              Env file defining `HERMES_DASHBOARD_BASIC_AUTH_*`. Merged into the gateway's
              `$HERMES_HOME/.env`, which is where serve reads it from. Required unless
              {option}`my.hermes.serve.host` is loopback.
            '';
          };
        };
        webui = {
          enable = lib.mkEnableOption "nesquena/hermes-webui, a third-party browser/PWA client that runs the agent in-process";
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = ''
              Address the web UI binds, upstream's default. Its login gates it either way,
              unlike serve's.
            '';
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 8787;
            description = "Port for the web UI.";
          };
          authFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Env file defining `HERMES_WEBUI_PASSWORD`. Its login is its own, not serve's.";
          };
        };
      };

      config = lib.mkIf cfg.enable (
        let
          agent = config.services.hermes-agent;
          user = config.my.primaryUser;
          home = config.users.users.${user}.home;
          # The gateway's own environment: all three services share one HERMES_HOME.
          agentEnv = config.systemd.services.hermes-agent.environment;
        in
        lib.mkMerge [
          {
            services.hermes-agent = {
              enable = true;
              inherit user;
              group = config.users.users.${user}.group;
              createUser = false;
              # It runs as the owner, so its state is the owner's: this lands HERMES_HOME on ~/.hermes.
              stateDir = home;
              addToSystemPackages = true;
              inherit (cfg) environmentFiles;
            };

            systemd.services.hermes-agent.serviceConfig = {
              # Upstream's own generated unit has these; their nix module drops them.
              # Exit codes are sysexits.h, from the gateway's restart protocol.
              RestartForceExitStatus = 75; # EX_TEMPFAIL: drained on purpose, restart
              RestartPreventExitStatus = 78; # EX_CONFIG: fatal config, stop restarting
              ExecReload = "${pkgs.coreutils}/bin/kill -USR1 $MAINPID";
              ExecStopPost = "-${agent.package.hermesVenv}/bin/python3 -m gateway.cgroup_cleanup";
              KillMode = "mixed";
            };
          }

          # Upstream's module doesn't have a `hermes serve` unit.
          (lib.mkIf cfg.serve.enable {
            services.hermes-agent.environmentFiles = lib.optional (
              cfg.serve.authFile != null
            ) cfg.serve.authFile;

            systemd.services.hermes-serve = {
              description = "Hermes Agent backend server";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];

              environment = {
                inherit (agentEnv) HOME HERMES_HOME HERMES_MANAGED;
              };

              serviceConfig = {
                User = agent.user;
                Group = agent.group;
                WorkingDirectory = agent.workingDirectory;
                # written by the gateway module's activation from its environmentFiles
                EnvironmentFile = "-${agentEnv.HERMES_HOME}/.env";
                # --skip-build: the web UI is prebuilt, npm isn't here.
                ExecStart = "${agent.package}/bin/hermes serve --host ${cfg.serve.host} --port ${toString cfg.serve.port} --skip-build";
                Restart = "always";
                RestartSec = 5;
                UMask = "0007";

                NoNewPrivileges = true;
                ProtectSystem = "strict";
                ProtectHome = false;
                ReadWritePaths = [
                  agent.stateDir
                  agent.workingDirectory
                ];
                PrivateTmp = true;
              };

              # Skills and slash commands resolve `hermes` by name; bash/git/ripgrep/node come from
              # the package's own wrapper, and coreutils is in every unit's default PATH already.
              path = [ agent.package ];
            };
          })

          (lib.mkIf cfg.webui.enable {
            services.hermes-webui = {
              enable = true;
              inherit (cfg.webui) host port;
              inherit user;
              group = config.users.users.${user}.group;
              hermesHome = agentEnv.HERMES_HOME;
              # the container is ephemeral, and passkeys live in here
              stateDir = "${home}/.hermes-webui";
              # it derives HERMES_WEBUI_PYTHON from the agent package's passthru.hermesVenv
              agent.package = agent.package;
              environmentFiles = lib.optional (cfg.webui.authFile != null) cfg.webui.authFile;
            };
          })
        ]
      );
    };
}
