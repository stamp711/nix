# Tests config/read-annotations/default.nix: fixtures and comparison with NVIDIA's parser.
{ pkgs, kernelSource }:
let
  readAnnotations = import ../. { inherit (pkgs) lib; };
  configsByArch = pkgs.lib.genAttrs (builtins.attrValues kernelSource.architectures) (
    arch:
    readAnnotations {
      inherit arch;
      file = "${kernelSource.src}/${kernelSource.annotationsPath}";
    }
  );
  nixConfigs = pkgs.writeText "nix-configs.json" (builtins.toJSON configsByArch);
in
assert import ./cases.nix { inherit (pkgs) lib; };
pkgs.runCommand "linux-nvidia-read-annotations-test"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    inherit nixConfigs;
    inherit (kernelSource) src annotationsPath;
  }
  ''
    python3 ${./compare-upstream.py} "$src" "$annotationsPath" "$nixConfigs"
    touch "$out"
  ''
