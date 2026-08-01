# Hermes Agent: upstream's gateway module plus the parts it leaves out, the backend server, and the web UI.
{ inputs, ... }:
{
  flake.nixosModules.hermes-agent =
    { config, pkgs, ... }:
    let
      cfg = config.services.hermes-agent;
      user = config.my.primaryUser;
      home = config.users.users.${user}.home;
      # All three must land on one HERMES_HOME, so take the gateway's rather than restate it.
      agentEnv = config.systemd.services.hermes-agent.environment;
    in
    {
      imports = [
        inputs.hermes-agent.nixosModules.default
        inputs.hermes-webui.nixosModules.default
      ];

      # Runs the agent in-process off the same HERMES_HOME; the browser/PWA client.
      services.hermes-webui = {
        enable = true;
        host = "0.0.0.0";
        port = 8787;
        inherit user;
        group = config.users.users.${user}.group;
        hermesHome = agentEnv.HERMES_HOME;
        # the container is ephemeral, and passkeys live in here
        stateDir = "${home}/.hermes-webui";
        # it derives HERMES_WEBUI_PYTHON from the agent package's passthru.hermesVenv
        agent.package = cfg.package;
      };

      services.hermes-agent = {
        enable = true;
        inherit user;
        group = config.users.users.${user}.group;
        createUser = false;
        # It runs as the owner, so its state is the owner's: this lands HERMES_HOME on ~/.hermes.
        stateDir = home;
        addToSystemPackages = true;
      };

      systemd.services.hermes-agent = {
        serviceConfig = {
          # Upstream's own generated unit has these; their nix module drops them.
          # Exit codes are sysexits.h, from the gateway's restart protocol.
          RestartForceExitStatus = 75; # EX_TEMPFAIL: drained on purpose, restart
          RestartPreventExitStatus = 78; # EX_CONFIG: fatal config, stop restarting
          ExecReload = "${pkgs.coreutils}/bin/kill -USR1 $MAINPID";
          ExecStopPost = "-${cfg.package.hermesVenv}/bin/python3 -m gateway.cgroup_cleanup";
          KillMode = "mixed";
        };
      };

      # Upstream's module doesn't have the `hermes serve` unit.
      # It needs the same HERMES_HOME as the other two.
      systemd.services.hermes-serve = {
        description = "Hermes Agent backend server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        environment = {
          inherit (agentEnv) HOME HERMES_HOME HERMES_MANAGED;
        };

        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.workingDirectory;
          # written by the gateway module's activation from its environmentFiles
          EnvironmentFile = "-${agentEnv.HERMES_HOME}/.env";
          # NOTE: Binding 0.0.0.0 will refuse to start without auth from environmentFiles.
          # --skip-build: the web UI is prebuilt, npm isn't here.
          ExecStart = "${cfg.package}/bin/hermes serve --host 0.0.0.0 --port 9119 --skip-build";
          Restart = "always";
          RestartSec = 5;
          UMask = "0007";

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = false;
          ReadWritePaths = [
            cfg.stateDir
            cfg.workingDirectory
          ];
          PrivateTmp = true;
        };

        # Skills and slash commands resolve `hermes` by name; bash/git/ripgrep/node come from
        # the package's own wrapper, and coreutils is in every unit's default PATH already.
        path = [ cfg.package ];
      };
    };
}
