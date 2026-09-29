# File loading: nested relative includes, ordering, root headers and cycles.
{ lib }:
let
  readAnnotations = import ../. { inherit lib; };
  read =
    file:
    readAnnotations {
      inherit file;
      arch = "arm64";
    };
  config = read ./fixtures/root;
  fails = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
in
# Root headers select nvidia, even though the included base only lists generic.
assert config.CONFIG_FLAVOUR == "m";
# Includes are expanded at their position, with paths relative to their own file.
assert config.CONFIG_INHERITED == "y";
assert config.CONFIG_ARCH_OVERRIDE == "m";
assert config.CONFIG_LATE_OVERRIDE == "y";
# Both Nix paths and strings work without creating a separate fixture store path.
assert read (toString ./fixtures/root) == config;
# Repeating an include on a separate branch is allowed; recursive includes fail.
assert (read ./fixtures/repeated).CONFIG_INHERITED == "y";
assert fails (read ./fixtures/cycle);
true
