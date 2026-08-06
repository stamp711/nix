# Builds the script that renders one file. It is written private and complete and
# then swapped in, so nothing ever reads a half-written file.
{
  lib,
  pkgs,
  name,
  content,
  placeholders,
  # Shell that sets `dir`: under home-manager the directory is only known to a shell.
  dirScript,
  # Mode of that directory: a system one has to be traversable by the services
  # that read out of it, a user's own does not.
  dirMode,
  # Set on home-manager: a stable path pointing at dir, made here so a consumer
  # rendering on its own gets it too.
  linkDir ? null,
  mode,
  # null on home-manager, where the file is the user's own.
  owner ? null,
  group ? null,
}:
let
  inherit (lib) escapeShellArg concatStringsSep;

  # Quote a secret path so the shell expands it: under home-manager agenix hands
  # out paths below `$XDG_RUNTIME_DIR` or `getconf DARWIN_USER_TEMP_DIR`.
  quote = p: ''"${toString p}"'';

  # A template ending in a newline, which one built by `toJSON` does not.
  template = escapeShellArg (
    pkgs.writeText "${name}.in" (if lib.hasSuffix "\n" content then content else content + "\n")
  );

  # Everything at once, and out of the shell: a value read here is never run as
  # shell, nor handed to a child in its environment.
  replacer = pkgs.writers.writePython3Bin "age-template-replace" { } ''
    import re
    import sys

    # The file's own name, so that a failure says which one: the paths below are
    # a store path and a temporary.
    NAME, TEMPLATE, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
    ARGS = sys.argv[4:]

    values = {}
    for i in range(0, len(ARGS), 2):
        with open(ARGS[i + 1]) as f:
            values[ARGS[i]] = f.read().strip("\n")

    with open(TEMPLATE) as f:
        data = f.read()

    unknown = set()


    def substitute(match):
        key = match.group(1) or match.group(2)
        if key not in values:
            unknown.add(key)
            return match.group(0)
        return values[key]


    # A whole name, so $token cannot match the start of $tokenId.
    WORD = r"[A-Za-z_][A-Za-z0-9_]*"
    PLACEHOLDER = re.compile(r"\$\{(" + WORD + r")\}|\$(" + WORD + r")")

    data = PLACEHOLDER.sub(substitute, data)
    if unknown:
        sys.exit(
            "age-template: %s: nothing provides %s"
            % (NAME, ", ".join("$" + u for u in sorted(unknown)))
        )

    with open(OUT, "w") as f:
        f.write(data)
  '';

  arguments = concatStringsSep " \\\n  " (
    lib.mapAttrsToList (placeholder: file: "${escapeShellArg placeholder} ${quote file}") placeholders
  );
in
# The script carries coreutils for the GNU's `mv -T` on darwin.
lib.getExe (
  pkgs.writeShellApplication {
    name = "age-template-${name}";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      ${dirScript}

      mkdir -p "$dir"
      chmod ${escapeShellArg dirMode} "$dir"
      ${lib.optionalString (linkDir != null) ''
        if [ -e ${escapeShellArg linkDir} ] && [ ! -L ${escapeShellArg linkDir} ]; then
          echo ${escapeShellArg "age-template: ${linkDir} exists and is not a symlink"} >&2
          exit 1
        fi
        mkdir -p ${escapeShellArg (builtins.dirOf linkDir)}
        ln -sfn "$dir" ${escapeShellArg linkDir}
      ''}

      # Unique, since the unit and a consumer may render the same file at once.
      # mktemp gives 0600, and the final mode is applied last, as it may forbid writing.
      tmp="$(mktemp "$dir"/${escapeShellArg ".render-${name}"}.XXXXXX)"
      trap 'rm -f "$tmp"' EXIT

      ${lib.getExe replacer} ${escapeShellArg name} ${template} "$tmp" \
        ${arguments}

      # Nothing to swap in if it already says this: the inode is left alone, so a
      # bind mount of it does not go stale.
      if cmp -s "$tmp" "$dir"/${escapeShellArg name}; then
        exit 0
      fi

      # Mode before owner, so the file is never writable by whoever ends up owning it.
      chmod ${escapeShellArg mode} "$tmp"
      ${lib.optionalString (owner != null) ''
        chown ${escapeShellArg (owner + ":" + group)} "$tmp"
      ''}
      # -T, or a directory left at that name would quietly swallow the file.
      mv -Tf "$tmp" "$dir"/${escapeShellArg name}
    '';
  }
)
