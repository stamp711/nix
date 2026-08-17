# The daemon tries to self-update at runtime.
{
  perSystem =
    { lib, pkgs, ... }:
    {
      packages.raft-computer =
        let
          version = "1.0.17";
          targets = {
            x86_64-linux = {
              file = "raft-computer-linux-x64";
              sha256 = "39f6d7a84d38b2dc1d8b70958bfcecefc0af290b2bfcfc6d8bca197a5b34bb30";
            };
            aarch64-linux = {
              file = "raft-computer-linux-arm64";
              sha256 = "1dc518e6a32f8b9e1523736c8860702476ff81dde1a1d26e51c64ee80b4b1aed";
            };
            aarch64-darwin = {
              file = "raft-computer-darwin-arm64";
              sha256 = "615469000798367af32308ccbbb07c44cb4d5c4785e147c823f6cbb38fe7250c";
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
