{ lib, self, ... }:
{
  flake.homeModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.codex.appServer;
    in
    {
      options.my.codex.appServer = {
        enable = lib.mkEnableOption "the shared local codex app-server daemon";
        remoteControl = lib.mkEnableOption "remote control, letting paired ChatGPT clients drive this machine";

        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = {
            https_proxy = "http://proxy.corp:8080";
          };
          description = "Extra daemon environment.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = pkgs.stdenv.hostPlatform.isLinux;
            message = "my.codex.appServer needs systemd user services (Linux only).";
          }
        ];

        systemd.user.services.codex-app-server = {
          Unit = {
            Description = "Codex app-server daemon";
            # Restart the daemon when its declarative settings change.
            X-Restart-Triggers = [
              ((pkgs.formats.toml { }).generate "codex-app-server-config.toml" config.programs.codex.settings)
            ];
          };
          Install.WantedBy = [ "default.target" ];
          Service = {
            # codex won't resolve the socket under a missing CODEX_HOME.
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/.codex";
            # Load the shell environment before replacing zsh with the daemon.
            ExecStart = lib.escapeShellArgs [
              "${pkgs.zsh}/bin/zsh"
              "-lic"
              (
                "exec "
                + lib.escapeShellArgs (
                  [
                    (lib.getExe config.programs.codex.package)
                    "app-server"
                  ]
                  ++ lib.optional cfg.remoteControl "--remote-control"
                  ++ [
                    "--listen"
                    "unix://"
                  ]
                )
              )
            ];
            WorkingDirectory = "%h";
            # Remote-control failures are silent at the default level.
            Environment = [
              "RUST_LOG=codex_app_server_transport=info"
            ]
            ++ lib.mapAttrsToList (name: value: "${name}=${value}") (
              self.lib.mergeDisjoint [
                cfg.environment
                {
                  # Match upstream's disabled-start marker; omitting --remote-control restores persisted state.
                  # https://github.com/openai/codex/blob/rust-v0.157.1/codex-rs/app-server-daemon/src/backend/pid.rs#L405-L415
                  CODEX_INTERNAL_APP_SERVER_REMOTE_CONTROL_DISABLED = if cfg.remoteControl then "0" else "1";
                }
              ]
            );
            Restart = "on-failure";
          };
        };
      };
    };
}
