{ inputs, lib, ... }:
{
  flake.homeModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.codex.web;
      packages = inputs.codex-web.packages.${pkgs.stdenv.hostPlatform.system};
      package = packages.default.overrideAttrs {
        # The GUI bundle is extracted during the build, after the usual patch phase.
        postBuild = ''
          patch --batch --fuzz=0 -p1 -d scratch/asar < ${./codex-web-project-grouping.patch}
        '';
      };

      start = pkgs.writeShellScript "codex-web-start" ''
        export CODEX_UNIX_SOCKET="''${CODEX_HOME:-$HOME/.codex}/app-server-control/app-server-control.sock"
        export CODEX_CLI_PATH=${lib.getExe packages.codex_remote_proxy}
        export CODEX_TPP_LOCAL_EXECUTOR_CLI_PATH=${lib.getExe config.programs.codex.package}

        # Let systemd retry if the daemon's socket is not ready yet.
        [[ -S "$CODEX_UNIX_SOCKET" ]] || exit 1
        exec ${lib.getExe' package "codex-web"} --host 127.0.0.1 --port ${toString cfg.port}
      '';
    in
    {
      options.my.codex.web = {
        enable = lib.mkEnableOption "the codex-web frontend for the shared app-server";

        port = lib.mkOption {
          type = lib.types.port;
          default = 8214;
          description = "Loopback HTTP port for codex-web.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = config.my.codex.appServer.enable;
            message = "my.codex.web requires my.codex.appServer.enable.";
          }
        ];

        systemd.user.services.codex-web = {
          Unit = {
            Description = "github:0xcaff/codex-web";
            Wants = [ "codex-app-server.service" ];
            After = [ "codex-app-server.service" ];
          };
          Install.WantedBy = [ "default.target" ];
          Service = {
            # Load login/proxy environment without interactive shell plugins.
            ExecStart = "${pkgs.zsh}/bin/zsh -lc 'exec ${start}'";
            Restart = "on-failure";
          };
        };
      };
    };
}
