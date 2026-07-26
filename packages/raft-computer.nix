# The daemon tries to self-update at runtime.
{
  perSystem =
    { lib, pkgs, ... }:
    {
      packages.raft-computer =
        let
          version = "1.0.14";
          targets = {
            x86_64-linux = {
              file = "raft-computer-linux-x64";
              sha256 = "a0d9e76e1fdfd8853dad6e9561845b71426724dfdcb6982b2d304d35dac8bccc";
            };
            aarch64-linux = {
              file = "raft-computer-linux-arm64";
              sha256 = "7493b5a912433da208e24b7ce89f9d9bf542b6cf6f0895844d8199fdccc97515";
            };
            aarch64-darwin = {
              file = "raft-computer-darwin-arm64";
              sha256 = "04e2e804b55df87a9609f2ac2dfd5f732202edd333c6dbcac37e6880b9a2ebd1";
            };
          };
          target =
            targets.${pkgs.stdenv.hostPlatform.system}
              or (throw "raft-computer: unsupported system ${pkgs.stdenv.hostPlatform.system}");
        in
        pkgs.stdenv.mkDerivation {
          pname = "raft-computer";
          inherit version;
          src = pkgs.fetchurl {
            url = "https://cdn.raft.build/computer/${version}/${target.file}";
            inherit (target) sha256;
          };
          dontUnpack = true;
          dontStrip = true; # would corrupt the SEA blob / break the signed macOS binary
          nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
          buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            pkgs.stdenv.cc.cc.lib
            pkgs.zlib
          ]; # Node SEA: glibc + libstdc++
          installPhase = "install -Dm755 $src $out/bin/raft-computer";
        };
    };
}
