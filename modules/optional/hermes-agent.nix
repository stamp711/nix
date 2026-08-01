# Hermes Agent: upstream's gateway module plus the parts it leaves out, and the client backend.
{ lib, inputs, ... }:
{
  flake.nixosModules.hermes-agent =
    { config, pkgs, ... }:
    let
      cfg = config.services.hermes-agent;
      user = config.my.primaryUser;
      home = config.users.users.${user}.home;
    in
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      services.hermes-agent = {
        enable = true;
        inherit user;
        group = config.users.users.${user}.group;
        createUser = false;
        # The container is ephemeral; only /persist and the home bind survive.
        stateDir = "/persist/hermes";
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
          # ProtectSystem=strict, and the agent edits the owner's checkouts.
          ReadWritePaths = [ home ];
        };
        # HOME is pinned to stateDir upstream, which hides git/jj/ssh identity from the agent.
        environment.HOME = lib.mkForce home;
      };

      # Upstream's module doesn't have the `hermes serve` unit.
      # The two processes need to share the same HERMES_HOME.
      systemd.services.hermes-serve = {
        description = "Hermes Agent backend server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        environment = {
          HOME = home;
          HERMES_HOME = "${cfg.stateDir}/.hermes";
          HERMES_MANAGED = "true";
        };

        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.workingDirectory;
          # written by the gateway module's activation from its environmentFiles
          EnvironmentFile = "-${cfg.stateDir}/.hermes/.env";
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
            home
          ];
          PrivateTmp = true;
        };

        # Skills and slash commands resolve `hermes` by name; bash/git/ripgrep/node come from
        # the package's own wrapper, and coreutils is in every unit's default PATH already.
        path = [ cfg.package ];
      };
    };
}
