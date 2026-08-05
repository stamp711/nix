# The daemon tries to self-update at runtime.
{
  perSystem =
    { lib, pkgs, ... }:
    {
      packages.raft-computer =
        let
          version = "1.0.15";
          targets = {
            x86_64-linux = {
              file = "raft-computer-linux-x64";
              sha256 = "3baa65acc66d24670ea48cb610ba43ac64ac5e1af360d15a47afb5dfbc1f0939";
            };
            aarch64-linux = {
              file = "raft-computer-linux-arm64";
              sha256 = "a65890ee3d0db95ac8afc38357fe974c9d0a0b07e5e62e4ef7d6e7e1408af947";
            };
            aarch64-darwin = {
              file = "raft-computer-darwin-arm64";
              sha256 = "87f298144f1dc13393af635d57dad15345a4b31cac032524bf3e9fec965bb51b";
            };
          };
          target =
            targets.${pkgs.stdenv.hostPlatform.system}
              or (throw "raft-computer: unsupported system ${pkgs.stdenv.hostPlatform.system}");

          # New in 1.0.15, the daemon loads it from beside its own executable.
          photonWasm = pkgs.fetchurl {
            url = "https://cdn.raft.build/computer/${version}/photon_rs_bg.wasm";
            sha256 = "10468181565c56004c867f3a4af96f89a0ef5a63a72f2b5fb12c1f1992a3615c";
          };
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
          installPhase = ''
            install -Dm755 $src $out/bin/raft-computer
            install -Dm444 ${photonWasm} $out/bin/photon_rs_bg.wasm
          '';
        };
    };
}
