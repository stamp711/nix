# Tests config/adaptations/default.nix: assumptions about the pinned upstream source.
{ pkgs, kernelSource }:
let
  inherit (pkgs) lib;
  inherit (kernelSource) src;
  readAnnotations = import ../read-annotations { inherit lib; };
  configsByArch = lib.genAttrs (builtins.attrValues kernelSource.architectures) (
    arch:
    readAnnotations {
      inherit arch;
      file = "${src}/${kernelSource.annotationsPath}";
    }
  );
  adaptations = import ./.;
  upstreamValuesMatch = lib.all (
    arch:
    lib.all (
      name:
      let
        actual = configsByArch.${arch}.${"CONFIG_${name}"} or null;
        expected = adaptations.overrides.${name}.expectedUpstream;
      in
      assert lib.assertMsg (actual == expected)
        "linux-nvidia: ${arch} CONFIG_${name} changed from ${builtins.toJSON expected} to ${builtins.toJSON actual}; review config/adaptations/default.nix";
      true
    ) (builtins.attrNames adaptations.overrides)
  ) (builtins.attrNames configsByArch);
  omittedSymbolsStillDeclared = lib.all (
    file:
    let
      text = "\n" + builtins.readFile "${src}/${file}";
    in
    lib.all (
      name:
      assert lib.assertMsg (lib.hasInfix "\nconfig ${name}\n" text)
        "linux-nvidia: CONFIG_${name} is no longer declared in ${file}; review config/adaptations/default.nix";
      true
    ) adaptations.omittedSymbolsByFile.${file}
  ) (builtins.attrNames adaptations.omittedSymbolsByFile);
in
assert upstreamValuesMatch;
assert omittedSymbolsStillDeclared;
pkgs.runCommand "linux-nvidia-adaptations-test" { } ''
  touch "$out"
''
