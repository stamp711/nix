{ lib, self, ... }:
let
  # Managed hooks don't need TUI trust.
  codexManagedHooks =
    { config, pkgs, ... }:
    let
      cfg = config.my.codex.managedHooks;
    in
    {
      options.my.codex.managedHooks = lib.mkOption {
        default = { };
        description = "Hooks codex runs unconditionally, named by their file under {file}`/etc/codex/hooks`.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              events = lib.mkOption {
                type = lib.types.listOf (
                  lib.types.enum [
                    "PreToolUse"
                    "PostToolUse"
                    "PermissionRequest"
                    "PreCompact"
                    "PostCompact"
                    "SessionStart"
                    "SessionEnd"
                    "SubagentStart"
                    "SubagentStop"
                    "Stop"
                    "UserPromptSubmit"
                  ]
                );
                description = "Codex hook events to fire on.";
              };
              matcher = lib.mkOption {
                type = lib.types.str;
                description = "Regex over codex tool names; file edits are `apply_patch`.";
              };
              command = lib.mkOption {
                type = lib.types.path;
                description = "Executable receiving the hook payload on stdin.";
              };
            };
          }
        );
      };

      config = lib.mkIf (cfg != { }) (
        let
          # codex only runs commands living under managed_dir
          managedDir = "/etc/codex/hooks";
          # The hooks grouped by event, the shape requirements.toml wants.
          byEvent = lib.zipAttrs (
            lib.mapAttrsToList (
              name: hook:
              lib.genAttrs hook.events (_: {
                inherit (hook) matcher;
                hooks = [
                  {
                    type = "command";
                    command = "${managedDir}/${name}";
                  }
                ];
              })
            ) cfg
          );
        in
        {
          environment.etc = self.lib.mergeDisjoint [
            {
              "codex/requirements.toml".source = (pkgs.formats.toml { }).generate "codex-requirements" {
                features.hooks = true;
                hooks = lib.attrsets.unionOfDisjoint { managed_dir = managedDir; } byEvent;
              };
            }
            (lib.mapAttrs' (name: hook: lib.nameValuePair "codex/hooks/${name}" { source = hook.command; }) cfg)
          ];
        }
      );
    };
in
{
  flake.nixosModules.my = codexManagedHooks;
  flake.darwinModules.my = codexManagedHooks;

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
          Unit.Description = "Codex app-server daemon";
          Install.WantedBy = [ "default.target" ];
          Service = {
            # codex won't resolve the socket under a missing CODEX_HOME.
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/.codex";
            # The default is stdio://.
            ExecStart = lib.escapeShellArgs (
              [
                (lib.getExe config.programs.codex.package)
                "app-server"
              ]
              ++ lib.optional cfg.remoteControl "--remote-control"
              ++ [
                "--listen"
                "unix://"
              ]
            );
            # Remote-control failures are silent at the default level.
            Environment = [
              "RUST_LOG=codex_app_server_transport=info"
            ]
            ++ lib.mapAttrsToList (name: value: "${name}=${value}") cfg.environment;
            Restart = "on-failure";
          };
        };
      };
    };
}
