# jj only records the working copy when a jj command runs, so edits made through
# other tooling stay invisible to the operator until one happens to run.
{
  flake.homeModules.agent-sandbox =
    { lib, pkgs, ... }:
    let
      snapshot = pkgs.writeShellScript "jj-snapshot" ''
        file=$(${lib.getExe pkgs.jq} -r '.tool_input.file_path // empty') || exit 0
        [ -n "$file" ] || exit 0
        # agents work in their own workspaces; nothing else is ours to snapshot
        case "$file" in "$HOME"/agents/*) ;; *) exit 0 ;; esac
        cd "$(dirname "$file")" 2>/dev/null || exit 0
        ${lib.getExe pkgs.jujutsu} status >/dev/null 2>&1 || true
      '';
    in
    {
      programs.claude-code.settings.hooks.PostToolUse = [
        {
          matcher = "Write|Edit";
          hooks = [
            {
              type = "command";
              command = "${snapshot}";
            }
          ];
        }
      ];
    };
}
