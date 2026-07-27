# A stale workspace serves old files with no error, so reads go wrong silently.
let
  reason = "The jj workspace at %s is stale, so its files are older than the repo and anything read from them is wrong. Run `jj workspace update-stale` there, then read the file again before editing it.";

  # pkgs + a jq file naming the edited file -> shell that exits 0 unless that workspace is stale
  detect = pkgs: editedPath: ''
    target=$(${pkgs.lib.getExe pkgs.jq} -rf ${editedPath}) || exit 0
    [ -n "$target" ] || exit 0
    case "$target" in "$HOME"/agents/*) ;; *) exit 0 ;; esac
    [ -d "$target" ] || target=$(dirname "$target")
    cd "$target" 2>/dev/null || exit 0

    # cheapest command that reads the working copy, so the verdict is jj's own
    err=$(${pkgs.lib.getExe pkgs.jujutsu} workspace list 2>&1 >/dev/null) || true
    case "$err" in
      *"working copy is stale"*) ;;
      *) exit 0 ;;
    esac
  '';

  # opencode and pi run hooks in-process, so they take a plugin rather than a script
  plugin =
    pkgs: src:
    pkgs.replaceVars src {
      inherit reason;
      jj = pkgs.lib.getExe pkgs.jujutsu;
    };
in
{
  flake.homeModules.agent-sandbox =
    { pkgs, ... }:
    let
      guard = pkgs.writeShellScript "jj-stale-check-before-read" ''
        ${detect pkgs ../claude-edited-path.jq}
        ${pkgs.lib.getExe pkgs.jq} -n --arg dir "$PWD" --arg reason ${pkgs.lib.escapeShellArg reason} '{
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: ($reason | sub("%s"; $dir))
          }
        }'
      '';
    in
    {
      # Bash is deliberately absent: it is how the block gets fixed.
      programs.claude-code.settings.hooks.PreToolUse = [
        {
          matcher = "Read|Edit|Write";
          hooks = [
            {
              type = "command";
              command = "${guard}";
            }
          ];
        }
      ];

      home.file.".opencode/plugin/jj-stale-check-before-read.js".source = plugin pkgs ./opencode.js;
      home.file.".pi/agent/extensions/jj-stale-check-before-read.ts".source = plugin pkgs ./pi.ts;
    };

  flake.nixosModules.agent-sandbox =
    { pkgs, ... }:
    {
      # codex blocks on exit 2 and relays stderr to the model
      my.codex.managedHooks.jj-stale-check-before-read = {
        event = "PreToolUse";
        matcher = "apply_patch";
        command = pkgs.writeShellScript "jj-stale-check-before-read-codex" ''
          ${detect pkgs ../codex-edited-path.jq}
          printf ${pkgs.lib.escapeShellArg reason} "$PWD" >&2
          exit 2
        '';
      };
    };
}
