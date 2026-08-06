# One entry point for both platforms: render every file, then drop whatever is
# no longer declared.
{ lib }:
{
  pkgs,
  dirScript,
  dirMode,
  files,
}:
let
  # Get a shell test that every secret an entry needs is readable.
  ready =
    entry:
    lib.concatMapStringsSep " && " (p: ''[ -r "${toString p}" ]'') (lib.attrValues entry.placeholders);
in
lib.getExe (
  pkgs.writeShellApplication {
    name = "age-template-render";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      ${dirScript}
      # The sweep below needs this directory even when nothing has rendered yet.
      # The mode is set here too, or it would be left at whatever the umask says.
      mkdir -p "$dir"
      chmod ${lib.escapeShellArg dirMode} "$dir"
      failed=0

      # Render what we can and report at the end.
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: entry: ''
          if ${if entry.placeholders == { } then "true" else ready entry}; then
            "${entry.renderScript}" || {
              echo ${lib.escapeShellArg "age-template: ${name}: render failed"} >&2
              failed=1
            }
          else
            echo ${lib.escapeShellArg "age-template: ${name}: secrets are not in place"} >&2
            failed=1
          fi
        '') files
      )}

      # `.render-*` are other writers' temporaries, which are none of our business.
      find "$dir" -mindepth 1 -maxdepth 1 -type f ! -name '.render-*' ${
        lib.concatMapStringsSep " " (n: "! -name ${lib.escapeShellArg n}") (lib.attrNames files)
      } -delete

      exit "$failed"
    '';
  }
)
