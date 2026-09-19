# Exercise the patched upstream checker with controlled make-config results.
{ pkgs }:
let
  patchGenerateConfig = import ../. { inherit (pkgs) lib writeText; };
  generateConfig = patchGenerateConfig "${pkgs.path}/pkgs/os-specific/linux/kernel/generate-config.pl";
  fakeMake = pkgs.writeShellScriptBin "make" ''
    cp "$fixtureConfig" "$BUILD_ROOT/.config"
  '';
in
pkgs.runCommand "linux-nvidia-config-checker-test"
  {
    nativeBuildInputs = [
      pkgs.perl
      fakeMake
    ];
    inherit generateConfig;
  }
  ''
    bash ${./run.sh}
    touch "$out"
  ''
