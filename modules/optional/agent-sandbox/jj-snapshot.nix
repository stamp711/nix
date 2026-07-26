# jj only records the working copy when a jj command runs, so edits made through
# other tooling stay invisible to the operator until one happens to run.
{
  flake.homeModules.agent-sandbox =
    { lib, pkgs, ... }:
    let
      # claude-code reports the edited file; codex reports only the session cwd.
      snapshot = pkgs.writeShellScript "jj-snapshot" ''
        target=$(${lib.getExe pkgs.jq} -r '.tool_input.file_path // .cwd // empty') || exit 0
        [ -n "$target" ] || exit 0
        # agents work in their own workspaces; nothing else is ours to snapshot
        case "$target" in "$HOME"/agents/*) ;; *) exit 0 ;; esac
        [ -d "$target" ] || target=$(dirname "$target")
        cd "$target" 2>/dev/null || exit 0
        ${lib.getExe pkgs.jujutsu} status >/dev/null 2>&1 || true
      '';
      hook = matcher: [
        {
          inherit matcher;
          hooks = [
            {
              type = "command";
              command = "${snapshot}";
            }
          ];
        }
      ];
    in
    {
      programs.claude-code.settings.hooks.PostToolUse = hook "Write|Edit";
      programs.codex.hooks.PostToolUse = hook "apply_patch";
    };
}
