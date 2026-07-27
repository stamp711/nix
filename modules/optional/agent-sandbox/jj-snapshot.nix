# jj only records the working copy when a jj command runs, so edits made through
# other tooling stay invisible to the operator until one happens to run.
let
  # claude-code reports the edited file, codex only the session cwd
  snapshot =
    pkgs:
    pkgs.writeShellScript "jj-snapshot" ''
      target=$(${pkgs.lib.getExe pkgs.jq} -r '.tool_input.file_path // .cwd // empty') || exit 0
      [ -n "$target" ] || exit 0
      # agents work in their own workspaces; nothing else is ours to snapshot
      case "$target" in "$HOME"/agents/*) ;; *) exit 0 ;; esac
      [ -d "$target" ] || target=$(dirname "$target")
      cd "$target" 2>/dev/null || exit 0
      ${pkgs.lib.getExe pkgs.jujutsu} status >/dev/null 2>&1 || true
    '';
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
              command = "${snapshot pkgs}";
            }
          ];
        }
      ];
    };

  # Codex ignores user-level hooks until a human trusts them in the TUI, which an
  # agent running `codex app-server` never can. Managed hooks are always on.
  flake.nixosModules.agent-sandbox =
    { pkgs, ... }:
    let
      # commands must live under managed_dir
      managedDir = pkgs.runCommand "codex-managed-hooks" { } ''
        mkdir -p $out
        ln -s ${snapshot pkgs} $out/jj-snapshot
      '';
    in
    {
      environment.etc."codex/requirements.toml".source =
        (pkgs.formats.toml { }).generate "codex-requirements"
          {
            features.hooks = true;
            hooks = {
              managed_dir = "${managedDir}";
              PostToolUse = [
                {
                  matcher = "apply_patch";
                  hooks = [
                    {
                      type = "command";
                      command = "${managedDir}/jj-snapshot";
                    }
                  ];
                }
              ];
            };
          };
    };
}
