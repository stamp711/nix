# Managed hooks don't need TUI trust.
{ lib, self, ... }:
let
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

      config = lib.mkIf (cfg != { }) (
        let
          # codex only runs commands living under managed_dir
          managedDir = "/etc/codex/hooks";
          # The hooks grouped by event, the shape requirements.toml wants.
          byEvent = lib.mapAttrs (
            _:
            lib.map (name: {
              inherit (cfg.${name}) matcher;
              hooks = [
                {
                  type = "command";
                  command = "${managedDir}/${name}";
                }
              ];
            })
          ) (lib.groupBy (name: cfg.${name}.event) (lib.attrNames cfg));
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
}
