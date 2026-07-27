# jj only records the working copy when a jj command runs, so edits made through
# other tooling stay invisible to the operator until one happens to run.
let
  # pkgs + a jq file naming the edited file -> the hook script
  snapshot =
    pkgs: editedPath:
    pkgs.writeShellScript "jj-snapshot-after-edit" ''
      target=$(${pkgs.lib.getExe pkgs.jq} -rf ${editedPath}) || exit 0
      [ -n "$target" ] || exit 0
      # agents work in their own workspaces; nothing else is ours to snapshot
      case "$target" in "$HOME"/agents/*) ;; *) exit 0 ;; esac
      [ -d "$target" ] || target=$(dirname "$target")
      cd "$target" 2>/dev/null || exit 0
      ${pkgs.lib.getExe pkgs.jujutsu} status >/dev/null 2>&1 || true
    '';

  # opencode and pi run hooks in-process, so they take a plugin rather than a script
  plugin = pkgs: src: pkgs.replaceVars src { jj = pkgs.lib.getExe pkgs.jujutsu; };
in
{
  flake.homeModules.agent-sandbox =
    { pkgs, ... }:
    {
      programs.claude-code.settings.hooks.PostToolUse = [
        {
          matcher = "Write|Edit";
          hooks = [
            {
              type = "command";
              command = "${snapshot pkgs ../claude-edited-path.jq}";
            }
          ];
        }
      ];

      home.file.".opencode/plugin/jj-snapshot-after-edit.js".source = plugin pkgs ./opencode.js;
      home.file.".pi/agent/extensions/jj-snapshot-after-edit.ts".source = plugin pkgs ./pi.ts;
    };

  flake.nixosModules.agent-sandbox =
    { pkgs, ... }:
    {
      my.codex.managedHooks.jj-snapshot-after-edit = {
        event = "PostToolUse";
        matcher = "apply_patch";
        command = snapshot pkgs ../codex-edited-path.jq;
      };
    };
}
