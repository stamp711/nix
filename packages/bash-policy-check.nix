# Judges a shell command against a set of rules.
# Command on stdin, rules on the command line, the strictest match's decision on stdout.
{
  perSystem =
    { pkgs, ... }:
    {
      packages.bash-policy-check = pkgs.writeShellApplication {
        name = "bash-policy-check";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.ast-grep
          pkgs.jq
        ];
        text = ''
          rules=""
          while [ $# -gt 0 ]; do
            case "$1" in
              # Two shifts, not `shift 2`, which fails and loops when the value is missing.
              --rules) rules=''${2:-}; shift; shift || true ;;
              *) echo "usage: bash-policy-check --rules DIR < COMMAND" >&2; exit 2 ;;
            esac
          done
          # An empty rule set would pass anything.
          [ -n "$rules" ] || { echo "bash-policy-check: no --rules given" >&2; exit 2; }

          # The command as a file: stdin takes one rule only, and .sh picks the grammar.
          script=$(mktemp --suffix=.sh)
          diagnostics=$(mktemp)
          trap 'rm -f "$script" "$diagnostics"' EXIT
          cat > "$script"

          # Exit status 1 means an error-severity rule matched, not that the scan failed.
          found=$(ast-grep scan -c "$rules"/sgconfig.yml --json=compact "$script" 2>"$diagnostics") || true
          if ! printf '%s' "$found" | jq -e 'type == "array"' >/dev/null; then
            # Not 0: unscannable is not the same as unobjectionable.
            cat "$diagnostics" >&2
            echo "bash-policy-check: could not scan the command" >&2
            exit 2
          fi

          # The strictest match, severity being how a decision survives ast-grep.
          verdict=$(printf '%s' "$found" | jq -c '
            [ .[] | { decision: { error: "deny", warning: "ask", info: "note" }[.severity], reason: (.message | sub("\\s+$"; "")) } ]
            | map(select(.decision != null))
            | sort_by({ deny: 0, ask: 1, note: 2 }[.decision])
            | first // empty
          ')
          [ -n "$verdict" ] || exit 0

          printf '%s\n' "$verdict"
          exit 1
        '';
      };
    };
}
