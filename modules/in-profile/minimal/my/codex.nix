# Managed hooks don't need TUI trust.
{ lib, ... }:
{
  flake.nixosModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.codex.managedHooks;
      # codex only runs commands living under managed_dir
      managedDir = "/etc/codex/hooks";

      # requirements.toml groups by event, we key by name; regroup
      byEvent = lib.mapAttrs (
        _:
        lib.map (hook: {
          inherit (hook) matcher;
          hooks = [
            {
              type = "command";
              command = "${managedDir}/${hook.name}";
            }
          ];
        })
      ) (lib.groupBy (hook: hook.event) (lib.mapAttrsToList (name: hook: hook // { inherit name; }) cfg));
    in
    {
      options.my.codex.managedHooks = lib.mkOption {
        default = { };
        description = "Hooks codex runs unconditionally, named by their file under {file}`/etc/codex/hooks`.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              event = lib.mkOption {
                type = lib.types.enum [
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
                ];
                description = "Codex hook event to fire on.";
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

      config = lib.mkIf (cfg != { }) {
        environment.etc = {
          "codex/requirements.toml".source = (pkgs.formats.toml { }).generate "codex-requirements" {
            features.hooks = true;
            hooks = {
              managed_dir = managedDir;
            }
            // byEvent;
          };
        }
        // lib.mapAttrs' (
          name: hook: lib.nameValuePair "codex/hooks/${name}" { source = hook.command; }
        ) cfg;
      };
    };
}
